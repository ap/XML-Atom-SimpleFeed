use 5.008001; # no good Unicode support? you lose
use strict;
use warnings;

package XML::Atom::SimpleFeed;

# ABSTRACT: No-fuss generation of Atom syndication feeds

# XXX split validations out into `is_valid` method or such to be able to call at `as_xml` time also?
# TODO add requirements from RFC 4287 as comments to the relevant sections of the code and mark todos etc

use Object::Tiny::Lvalue qw( feed encoding );
use XML::Builder;
use Carp::Clan '^XML::Atom::SimpleFeed(?:\z|::)';

sub new {
	my $self = bless {}, shift;
	$self->feed = XML::Atom::SimpleFeed::Tag::Feed->new( @_ );
	return $self;
}

sub add_entry  {
	my $self = shift;
	$self->feed->add_entry( @_ );
	return $self;
}

sub as_xml {
	my $self = shift;
	my ( $builder ) = @_;
	my $atom_ns = 'http://www.w3.org/2005/Atom';
	$builder = XML::Builder->new( encoding => 'us-ascii' ) if not $builder;
	eval { $builder->register_ns( $atom_ns => '' ) };
	$self->feed->as_xml( $builder->register_ns( $atom_ns ) );
}

sub as_string {
	my $self = shift;
	return $self->as_xml( @_ )->as_string;
}

sub default_generator {
	my $class = shift;
	return (
		uri      => 'http://search.cpan.org/dist/' . join( '-', split /::/, $class ) . '/',
		version  => $class->VERSION || 'git',
		name     => $class,
	)
}

# LEGACY METHODS (only left here for backcompat)
sub no_generator {
	my $self = shift;
	for my $g ( $self->feed->generator ) {
		undef $g if $g and $g->_default;
	}
	return $self;
}
sub print {
	my $self = shift;
	my ( $fh ) = @_;
	my $old_fh = select;
	select $fh if defined $fh;
	local $, = local $\ = '';
	my $res = print $self->as_string;
	select $old_fh if defined $fh;
	return $res;
}
sub save_file { croak q{no longer supported, use 'print' instead and pass in a filehandle} }

#######################################################################

package XML::Atom::SimpleFeed::Construct;

sub tag    { die }
sub as_xml { die }

sub class_for_name { "XML::Atom::SimpleFeed::Tag::\u$_[1]" }

sub make_subclass {
	my $class = shift;
	for my $tag ( @_ ) {
		my $subclass = $class->class_for_name( $tag );
		eval qq(
			package $subclass;
			use parent -norequire => '$class';
			sub tag { '$tag' }
		);
	}
}

sub make_element {
	my $self = shift;
	my $name = shift;
	my $class = $self->class_for_name( $name );
	return $class->new( @_ );
}

sub croak {
	my $self = shift;
	XML::Atom::SimpleFeed::croak( @_ );
}

sub carp {
	my $self = shift;
	XML::Atom::SimpleFeed::carp( @_ );
}

#######################################################################

package XML::Atom::SimpleFeed::Construct::Simple;
use Object::Tiny::Lvalue qw( content );
use parent -norequire => 'XML::Atom::SimpleFeed::Construct';

__PACKAGE__->make_subclass( qw( icon id logo ) );

sub new {
	my $class = shift;
	unshift @_, 'content' if @_ == 1;
	bless { @_ }, $class;
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;
	$atom_ns->qname( $self->tag, $self->content );
}

#######################################################################

package XML::Atom::SimpleFeed::Construct::Date;
use parent -norequire => 'XML::Atom::SimpleFeed::Construct::Simple';

__PACKAGE__->make_subclass( qw( published updated ) );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	my $dt = $self->content;
	eval { $dt = $dt->epoch }; # convert to epoch to avoid dealing with everyone's TZ crap
	$self->content = POSIX::strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime $dt ) unless $dt =~ /[^0-9]/;

	return $self;
}

#######################################################################

package XML::Atom::SimpleFeed::Construct::Person;
use Object::Tiny::Lvalue qw( name email uri );
use parent -norequire => 'XML::Atom::SimpleFeed::Construct';

__PACKAGE__->make_subclass( qw( author contributor ) );

sub new {
	my $class = shift;
	unshift @_, 'name' if @_ == 1;
	my $self = bless { @_ }, $class;
	$self->croak( "name required for ${\$self->tag} element" ) if not defined $self->name;
	return $self;
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;
	$atom_ns->qname( $self->tag, map {
		my $val = $self->$_;
		defined $val ? $atom_ns->qname( $_, $val ) : ();
	} qw( name email uri ) );
}

#######################################################################

package XML::Atom::SimpleFeed::Construct::Text;
use Object::Tiny::Lvalue qw( type content );
use parent -norequire => 'XML::Atom::SimpleFeed::Construct';

__PACKAGE__->make_subclass( qw( title subtitle rights summary content ) );

# FIXME doesn't support @src attribute for $name eq 'content' yet
# TODO make text construct subclass of content construct to implement @src and disallow MIME types

sub new {
	my $class = shift;
	unshift @_, 'content' if @_ == 1;
	my $self = bless { @_ }, $class;

	$self->croak( "content required for ${\$self->tag} element" ) unless defined $self->content;

	if ( not defined $self->type ) {
		$self->type = 'html';
	}
	else {
		$self->croak( "type '${\$self->type}' not allowed in ${\$self->tag} element" )
			if  $self->tag  ne 'content'
			and $self->type !~ /\A(?:text|x?html)\z/;
	}

	return $self;
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;

	my $t = $self->type;
	my $c = $self->content;

	if (
		# FIXME do these cover all cases correctly?
		   ( $t eq  'html' and $c !~ /[<&]/ )
		or ( $t eq 'xhtml' and $c !~ /</ )
	) {
		$t = 'text';
		$c =~ s/[\n\t]+/ /g;
	}
	elsif ( $t eq 'xhtml' ) {
		my $builder = $atom_ns->builder;
		$c = $builder->unsafe( $c );
		$c = $builder->qname( 'http://www.w3.org/1999/xhtml' => div => $c )->root;
	}
	elsif ( $t ne 'text' ) {
		# FIXME non-XML/text media types must be base64 encoded!
	}

	$atom_ns->qname( $self->tag, ( $t ne 'text' ? { type => $t } : () ), $c );
}

#######################################################################

package XML::Atom::SimpleFeed::Construct::AttrValue;
use parent -norequire => 'XML::Atom::SimpleFeed::Construct';

__PACKAGE__->make_subclass( qw( link category ) ); # see overridden `make_subclass` below

sub required_attr  { die }
sub optional_attrs { die }

sub attr_names { $_[0]->required_attr, $_[0]->optional_attrs }

sub new {
	my $class = shift;
	my $req = $class->required_attr;
	unshift @_, $req if @_ == 1;
	my $self = bless { @_ }, $class;
	$self->croak( "$req required for ${\$self->tag} element" ) if not defined $self->$req;
	return $self;
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;

	my %attr = map {
		my $v = $self->$_;
		defined $v ? ( $_ => $v ) : ();
	} $self->attr_names;

	$atom_ns->qname( $self->tag, \%attr );
}

sub make_subclass {
	my $class = shift;
	$class->SUPER::make_subclass( @_ );
	for my $tag ( @_ ) {
		my $subclass = $class->class_for_name( $tag );
		eval qq(
			package $subclass;
			use Object::Tiny::Lvalue __PACKAGE__->attr_names;
		);
	}
}

package XML::Atom::SimpleFeed::Tag::Link;
sub required_attr  { 'href' }
sub optional_attrs { qw( rel type title hreflang length ) }

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );
	# $self->croak( "link '$attr->{ href }' is not a valid URI" )
	# 	if $attr->href XXX FIXME
	$self->rel = 'alternate' if not defined $self->rel;
	return $self;
}

sub as_xml {
	my $self = shift;
	# omit atom:link/@rel value when possible:
	local $self->{ rel } if $self->rel eq 'alternate';
	return $self->SUPER::as_xml( @_ );
}

sub permalink {
	my $self = shift;
	return $self->rel eq 'alternate' ? $self->href : ();
}

package XML::Atom::SimpleFeed::Tag::Category;
sub required_attr  { 'term' }
sub optional_attrs { qw( scheme label ) }

#######################################################################

package XML::Atom::SimpleFeed::Tag::Generator;
use Object::Tiny::Lvalue qw( name uri version _default );
use parent -norequire => 'XML::Atom::SimpleFeed::Construct';

sub tag { 'generator' }

sub new {
	my $class = shift;
	unshift @_, 'name' if @_ == 1;
	my $self = bless { @_ }, $class;
	$self->croak( "name required for ${\$self->tag} element" ) if not defined $self->name;
	return $self;
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;

	my %attr = map {
		my $v = $self->$_;
		defined $v ? ( $_ => $v ) : ();
	} qw( uri version );

	$atom_ns->qname( $self->tag, \%attr, $self->name );
}

#######################################################################

package XML::Atom::SimpleFeed::Construct::Container;
use Object::Tiny::Lvalue qw( content _singular_for _permalink id updated );
use parent -norequire => 'XML::Atom::SimpleFeed::Construct';

__PACKAGE__->make_subclass( qw( feed entry ) ); # see overridden `make_subclass` below

sub required { die }
sub optional { die }
sub singular { die }

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	$self->_singular_for = {};
	$self->_singular_for->{ $_ } = 1 for $self->singular;

	for my $i ( 0 .. $#_ ) {
		next if $i % 2;
		my ( $elem, $arg ) = @_[ $i, $i + 1 ];
		my $t   = ref $arg;
		my @arg = 'ARRAY' eq $t ? @$arg : 'HASH' eq $t ? %$arg : $arg;
		$self->add( $elem => @arg );
	}

	if ( defined $self->_permalink and not defined $self->id ) {
		$self->carp( 'Falling back to alternate link as id' );
		$self->add( id => $self->_permalink );
	}

	$self->add( updated => time )
		if not defined $self->updated;

	if ( my @missing = grep { not defined $self->$_ } $self->required ) {
		my $missing = do {
			my @and;
			unshift @and, pop @missing if @missing;
			unshift @and, join ', ', @missing if @missing;
			join ' and ', @and;
		};
		$self->croak( "Missing $missing elements in ${\$self->tag}" );
	}

	return $self;
}

sub add {
	my $self = shift;
	my $name = shift;
	my $element = $self->make_element( $name, @_ );

	if ( $name eq 'link' and defined ( my $href = $element->permalink ) ) {
		$self->croak( "Too many permalinks for ${\$self->tag}" ) if defined $self->_permalink;
		$self->_permalink = $href;
	}

	if ( $self->_singular_for->{ $name } ) {
		$self->croak( "Too many $name elements for ${\$self->tag}" ) if defined $self->$name;
		$self->$name = $element;
	}
	else {
		$self->$name ||= [];
		push @{ $self->$name }, $element;
	}

	return $self;
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;
	my $sing = $self->_singular_for;

	$atom_ns->qname( $self->tag, map {
		my $o = $self->$_;
		map { defined $_ ? $_->as_xml( $atom_ns ) : () } ( $sing->{$_} ? $o : @$o );
	} $self->required, $self->optional );
}

sub make_subclass {
	my $class = shift;
	$class->SUPER::make_subclass( @_ );
	for my $tag ( @_ ) {
		my $subclass = $class->class_for_name( $tag );
		eval qq(
			package $subclass;
			use Object::Tiny::Lvalue __PACKAGE__->required, __PACKAGE__->optional;
		);
	}
}

package XML::Atom::SimpleFeed::Tag::Feed;
use parent -norequire => 'XML::Atom::SimpleFeed::Construct::Container';

sub required { qw( title id updated ) }
sub optional { qw( subtitle link icon logo author contributor rights generator category entry ) }
sub singular { qw( generator icon id logo rights subtitle title updated ) }

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_ );

	if ( not defined $self->generator ) {
		$self->add( generator => XML::Atom::SimpleFeed->default_generator, _default => 1 );
	}
	elsif ( $self->generator->name eq '' ) {
		undef $self->generator;
	}

	return $self;
}

sub add {
	my $self = shift;
	my $name = shift;

	if ( $name eq 'entry' ) {
		# FIXME check whether there is a feed-level `author`
	}

	return $self->SUPER::add( $name, @_ );
}

sub add_entry {
	my $self = shift;
	$self->add( entry => @_ );
}

sub as_xml {
	my $self = shift;
	my ( $atom_ns ) = @_;
	$atom_ns->builder->document( $self->SUPER::as_xml( $atom_ns ) );
}

package XML::Atom::SimpleFeed::Tag::Entry;
use parent -norequire => 'XML::Atom::SimpleFeed::Construct::Container';

sub required { qw( title id updated ) }
sub optional { qw( link summary content published author contributor category rights ) }
sub singular { qw( content id published rights summary ) }

# FIXME
# 
# o  atom:entry elements that contain no child atom:content element
#    MUST contain at least one atom:link element with a rel attribute
#    value of "alternate".
# 
# o  atom:entry elements MUST contain an atom:summary element in either
#    of the following cases:
#    *  the atom:entry contains an atom:content that has a "src"
#       attribute (and is thus empty).
#    *  the atom:entry contains content that is encoded in Base64;
#       i.e., the "type" attribute of atom:content is a MIME media type
#       [MIMEREG], but is not an XML media type [RFC3023], does not
#       begin with "text/", and does not end with "/xml" or "+xml".

####################################################################

!!'Funky and proud of it.';

__END__

=head1 SYNOPSIS

 use XML::Atom::SimpleFeed;
 
 my $feed = XML::Atom::SimpleFeed->new(
     title   => 'Example Feed',
     link    => 'http://example.org/',
     link    => { rel => 'self', href => 'http://example.org/atom', },
     updated => '2003-12-13T18:30:02Z',
     author  => 'John Doe',
     id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
 );
 
 $feed->add_entry(
     title     => 'Atom-Powered Robots Run Amok',
     link      => 'http://example.org/2003/12/13/atom03',
     id        => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a',
     summary   => 'Some text.',
     updated   => '2003-12-13T18:30:02Z',
     category  => 'Atom',
     category  => 'Miscellaneous',
 );
 
 $feed->print;

=head1 DESCRIPTION

This module provides a minimal API for generating Atom syndication feeds
quickly and easily. It supports all aspects of the Atom format, but has no
provisions for generating feeds with extension elements.

You can supply strings for most things, and the module will provide useful
defaults. When you want more control, you can provide data structures, as
documented, to specify more particulars.

=head1 INTERFACE

=head2 C<new>

XML::Atom::SimpleFeed instances are created by the C<new> constructor, which
takes a list of key-value pairs as parameters. The keys are used to create the
corresponding L<"Atom elements"|/ATOM ELEMENTS>. The following elements are
available:

=over

=item * L</C<id>> (I<omissible>)

=item * L</C<link>> (I<omissible>, multiple)

=item * L</C<title>> (B<required>)

=item * L</C<author>> (optional, multiple)

=item * L</C<category>> (optional, multiple)

=item * L</C<contributor>> (optional, multiple)

=item * L</C<generator>> (optional)

=item * L</C<icon>> (optional)

=item * L</C<logo>> (optional)

=item * L</C<rights>> (optional)

=item * L</C<subtitle>> (optional)

=item * L</C<updated>> (optional)

=back

To specify multiple instances of an element that may be given multiple times,
simply list multiple key-value pairs with the same key.

=head2 C<add_entry>

This method adds an entry into the Atom feed. It takes a list of key-value
pairs as parameters. The keys are used to create the corresponding
L<"Atom Elements"|/ATOM ELEMENTS>. The following elements are available:

=over

=item * L</C<author>> (B<required> unless there is a feed-level author, multiple)

=item * L</C<id>> (I<omissible>)

=item * L</C<link>> (B<required>, multiple)

=item * L</C<title>> (B<required>)

=item * L</C<category>> (optional, multiple)

=item * L</C<content>> (optional)

=item * L</C<contributor>> (optional, multiple)

=item * L</C<published>> (optional)

=item * L</C<rights>> (optional)

=item * L</C<summary>> (optional)

=item * L</C<updated>> (optional)

=back

To specify multiple instances of an element that may be given multiple times,
simply list multiple key-value pairs with the same key.

=head2 C<as_string>

Returns the XML representation of the feed as a string.

=head1 ATOM ELEMENTS

=head2 C<author>

A L</Person Construct> denoting the author of the feed or entry.

If you supply at least one author for the feed, you can omit this information
from entries; the feed's author(s) will be assumed as the author(s) for those
entries. If you do not supply any author for the feed, you B<must> supply one
for each entry.

=head2 C<category>

One or more categories that apply to the feed or entry. You can supply a string
which will be used as the category term. The full range of details that can be
provided by passing a hash instead of a string is as follows:

=over

=item C<term> (B<required>)

The category term.

=item C<scheme> (optional)

A URI that identifies a categorization scheme.

It is common to provide the base of some kind of by-category URL here. F.ex.,
if the weblog C<http://www.example.com/blog/> can be browsed by category using
URLs such as C<http://www.example.com/blog/category/personal>, you would supply
C<http://www.example.com/blog/category/> as the scheme and, in that case,
C<personal> as the term.

=item C<label> (optional)

A human-readable version of the term.

=back

=head2 C<content>

The actual, honest-to-goodness, body of the entry. This is like a
L</Text Construct>, with a couple of extras.

In addition to the C<type> values of a L</Text Construct>, you can also supply
any MIME Type (except multipart types, which the Atom format specification
forbids). If you specify a C<text/*> type, the same rules apply as for C<text>.
If you pass a C<*/xml> or C<*/*+xml> type, the same rules apply as for C<xhtml>
(except in that case there is no wrapper C<< <div> >> element). Any other type
will be transported as Base64-encoded binary.

XXX Furthermore, you can supply a C<src> key in place of the C<content> key. In
that case, the value of the C<src> key should be a URL denoting the actual
location of the content. FIXME This is not currently supported. XXX

=head2 C<contributor>

A L</Person Construct> denoting a contributor to the feed or entry.

=head2 C<generator>

The software used to generate the feed. Can be supplied as a string, or a hash
with C<uri>, C<version> and C<name> keys. Defaults to reporting
XML::Atom::SimpleFeed as the generator. To suppress the default and include no
C<generator> element in the feed, pass an empty string.

=head2 C<icon>

The URI of a small image whose width and height should be identical.

=head2 C<id>

A URI that is a permanent, globally unique identifier for the feed or entry
that B<MUST NEVER CHANGE>.

You are encouraged to generate a UUID using L<Data::UUID> for the purpose of
identifying entries/feeds. It should be stored alongside the resource
corresponding to the entry/feed, f.ex. in a column of the article table of your
weblog database. To use it as an identifier in the entry/feed, use the
C<urn:uuid:########-####-####-####-############> URI form.

If you do not specify an ID, the permalink will be used instead. This is
unwise, as permalinks do unfortunately occasionally change.
B<It is your responsibility to ensure that the permalink NEVER CHANGES.>

=head2 C<link>

A link element. You can either supply a bare string as the parameter, which
will be used as the permalink URI, or a hash. The permalink for a feed is
generally a browser-viewable weblog, upload browser, search engine results page
or similar web page; for an entry, it is generally a browser-viewable article,
upload details page, search result or similar web page. This URI I<should> be
unique. If you supply a hash, you can provide the following range of details in
the given hash keys:

=over

=item C<rel> (optional)

The link relationship. If omitted, defaults to C<alternate> (note that you can
only have one alternate link per feed/entry). Other permissible values are
C<related>, C<self>, C<enclosure> and C<via>, as well as any URI.

=item C<href> (B<required> URL)

Where the link points to.

=item C<type> (optional)

An advisory media type that provides a hint about the type of the resource
pointed to by the link.

=item C<hreflang> (optional)

The language of the resource pointed to by the link, an an RFC3066 language tag.

=item C<title> (optional)

Human-readable information about the link.

=item C<length> (optional)

A hint about the content length in bytes of the resource pointed to by the link.

=back

=head2 C<logo>

The URI of an image that should be twice as wide as it is high.

=head2 C<published>

A L</Date Construct> denoting the moment in time when the entry was first
published. This should never change.

=head2 C<rights>

A L</Text Construct> containing a human-readable statement of legal rights for
the content of the feed or entry. This is not intended for machine processing.

=head2 C<subtitle>

A L</Text Construct> containing an optional additional description of the feed.

=head2 C<summary>

A L</Text Construct> giving a short summary of the entry.

=head2 C<title>

A L</Text Construct> containing the title of the feed or entry.

=head2 C<updated>

A L</Date Construct> denoting the moment in time when the feed or entry was
last updated. Defaults to the current date and time if omitted.

In entries, you can use this element to signal I<significant> changes at your
discretion.

=head1 COMMON ATOM CONSTRUCTS

A number of Atom elements share a common structure. The following sections
outline the data you can (or must) pass in each case.

=head2 Date Construct

A string denoting a date and time in W3CDTF format. You can generate those
using something like

 use POSIX 'strftime';
 my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;

However, you can also simply pass a Unix timestamp (a positive integer) or an
object that responds to an C<epoch> method call. (Make sure that the timezone
reported by such objects is correct!)

The following datetime classes from CPAN are compatible with this interface:

=over 4

=item * L<Time::Piece|Time::Piece>

=item * L<DateTime|DateTime>

=item * L<Time::Moment|Time::Moment>

=item * L<Panda::Date|Panda::Date>

=item * L<Class::Date|Class::Date>

=item * L<Time::Object|Time::Object> (an obsolete precursor to L<Time::Piece|Time::Piece>)

=back

The following are not:

=over 4

=item * L<DateTime::Tiny|DateTime::Tiny>

This class lacks both an C<epoch> method or any way to emulate one E<ndash> as
well as any timezone support in the first place.

=item * L<Date::Handler|Date::Handler>

This class has a suitable methodE<hellip> but sadly, calls it C<Epoch>.

=back

=head2 Person Construct

You can supply a string to Person Construct parameters, which will be used as
the name of the person. The full range of details that can be provided by
passing a hash instead of a string is as follows:

=over

=item C<name> (B<required>)

The name of the person.

=item C<email> (optional)

The person's email address.

=item C<uri> (optional)

A URI to distinguish this person. This would usually be a homepage, but need
not actually be a dereferencable URL.

=back

=head2 Text Construct

You can supply a string to Text Construct parameters, which will be used as the
HTML content of the element.

FIXME details, text/html/xhtml

=head1 SEE ALSO

=over

=item * Atom Enabled (L<http://www.atomenabled.org/>)

=item * W3CDTF Spec (L<http://www.w3.org/TR/NOTE-datetime>)

=item * RFC 3066 (L<http://rfc.net/rfc3066.html>)

=item * L<XML::Atom::Syndication>

=item * L<XML::Feed>

=back

=head1 BUGS AND LIMITATIONS

In C<content> elements, the C<src> attribute cannot be used, and non-XML or
non-text media types do not get Base64-encoded automatically. This is a bug.

There are practically no tests. This is a bug.

Support for C<xml:lang> and C<xml:base> is completely absent. This is a bug and
should be partially addressed in a future version. There are however no plans
to allow these attributes on arbitrary elements.

There are no plans to ever support generating feeds with arbitrary extensions,
although support for specific extensions may or may not be added in the future.

The C<source> element is not and may never be supported.

Nothing is done to ensure that text constructs with type C<xhtml> and entry
contents using either that or an XML media type are well-formed. So far, this
is by design. You should strongly consider using an XML writer if you want to
include content with such types in your feed.
