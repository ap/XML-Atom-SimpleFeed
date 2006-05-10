#!/usr/bin/perl

=head1 NAME

XML::Atom::SimpleFeed - No-fuss generation of Atom syndication feeds

=head1 VERSION

This document describes XML::Atom::SimpleFeed version 0.8_003

FIXME That's the theory anyway. In practice, there are discrepances between
code and docs. But that shouldn't be too catastrophic since the documentation
inaccuracies mostly consist of omissions.

=head1 SYNOPSIS

    use XML::Atom::SimpleFeed;

    # Create the feed object
    my $atom = XML::Atom::SimpleFeed->new(
        title     => "My Atom Feed",
        subtitle  => "This is an example feed.  Nothing to see here.  Move along."
        link      => "http://www.example.com/blogs/",
        generator => 'Elite Blogs LLP',
        updated   => "2005-02-18T15:00:00Z",
    );

    # Add an entry to the feed
    $atom->add_entry(
        title     => "A Sample Entry",
        link      => "http://www.example.com/blogs/joe/entries/1234",
        content   => "This is the body of the entry"
        author    => { name => "J. Random Hacker", email => 'jrh@example.com' },
        published => "2005-02-18T15:30:00Z",
        updated   => "2005-02-18T16:45:00Z",
    );

    # Add a more complicated entry
    $atom->add_entry(
        title => 'A more complicated example.',
        link  => [
            href => 'http://www.example.com/blogs/quux/entries/1337',
            {
                rel  => 'via',
                href => 'http://www.example.com/blogs/foo/entries/1',
            }
        ],
        author => {
            name  => 'Foo Bar',
            uri   => 'http://www.example.com/blogs/foo/',
            email => 'foo@example.com'
        },
        rights    => 'Copyright 2005 by Foo Bar Inc.',
        category  => 'Technology',
        content   => 'I have nothing to say now.'
    );

    # Print out the feed
    $atom->print;


=head1 DESCRIPTION

This module provides a minimal API for generating Atom syndication feeds
quickly and easily. It supports all aspects of the Atom format, but it has no
provisions for generating feeds with extension elements.

You can supply strings for most things, and the module will provide useful
defaults. When you want more control, you can provide data structures, as
documented, to specify more particulars.

=head1 INTERFACE

=head2 Constructor

XML::Atom::SimpleFeed instances are created by the C<new> constructor:

    my $atom = XML::Atom::SimpleFeed->new( %arguments );

Parameters are supplied as key-value pairs, as follows:

=over

=item C<id> (I<omissible> URI)

A URI that is a permanent, globally unique identifier for the entry. This should B<never change>.

=item C<title> (B<required> L</Text Construct>)

The title of the feed.

=item C<subtitle> (optional L</Text Construct>)

An optional additional description of the feed.

=item C<category> (optional L</Category Construct>)

One or more categories that apply to the entry.

=item C<link> (I<omissible> L</Link Construct>)

The permalink for the syndicated resource. This is generally a browser-viewable weblog, upload browser, search engine results page or similar web page.

=item C<author> (optional L</Person Construct>)

The author of the feed.

=item C<rights> (optional L</Text Construct>)

The legal rights for the content of the feed.

=item C<generator> (optional string/hash)

The software used to generate the feed. Can be supplied as a string, or a hash with C<uri>, C<version> and C<name> keys. Defaults to reporting XML::Atom::SimpleFeed as the generator, which can be suppressed by explicitly passing an C<undef> value.

=item C<updated> (optional L</Date Construct>)

The date and time at which the feed was last updated. If omitted, the current date and time will be used.

=back

=head2 Methods

=over

=item C<add_entry>

This method adds an entry into the atom feed.  Its arguments are supplied as a hash, with the following keys:

=over

=item C<id> (I<omissible> URI)

A URI that is a permanent, globally unique identifier for the entry. This should B<never change>.

You are encouraged to generate a UUID using L<Data::UUID> for the purpose. It should be stored alongside the resource corresponding to this entry, f.ex. in a column of the article table of your weblog database. To use it as an identifier in the feed, use the C<urn:uuid:########-####-####-####-############> URI form.

If you do not specify an ID, the permalink will be used instead. It is your responsibility to ensure that the permalink C<never changes>.

=item C<title> (B<required> L</Text Construct>)

The title of the entry.

=item C<link> (B<required> L</Link Construct>)

The permalink for the entry. This is generally a browser-viewable article, upload details page, search result or similar web page. It I<should> be unique.

=item C<summary> (optional L</Text Construct>)

A short summary of the entry.

=item C<content> (optional Content Construct)

The actual, honest-to-goodness, body of the entry. This is a L</Text Construct>, with a couple of extras.

In addition to the C<type> values of a L</Text Construct>, you can also supply any MIME type (except multipart types, which the Atom format specification forbids). If you specify a C<text/*> type, the same rules apply as for C<text>. If you pass a C<*/xml> or C<*/*+xml> type, the same rules apply as for C<xhtml> (except in that case there is no wrapper C<< <div> >> element). Any other type will be transported as Base64-encoded binary.

Furthermore, you can supply a C<src> key in place of the C<content> key. In that case, the value of the C<src> key should be a URL denoting the actual location of the content.

=item C<category> (optional L</Category Construct>)

One or more categories that apply to the entry.

=item C<author> (B<possibly required> L</Person Construct>)

The author of the entry. If no author was given for the feed as a whole, this is B<required>.

=item C<rights> (optional L</Text Construct>)

The legal rights for the content of this entry.

=item C<published> (optional L</Date Construct>)

The date and time the entry was first published. This should never change.

=item C<updated> (optional L</Date Construct>)

The date and time the entry was last updated. You can use this to signal changes to the entry at your discretion. Defaults to the current date and time.

=back

=item C<as_string>

Returns the text of the feed as a string.

=item C<print>

Outputs the feed to STDOUT.

=item C<save_file( $file )>

Saves the feed into C<$file>, which can be a filename or filehandle.

=back

=head1 ATOM CONSTRUCTS

Many of the parameters accepted by the C<new> constructor and the C<add_entry> method are identified as a particular construct. These are pieces of information with a common structure. The following sections outline the data you can (or must) pass in each case.

=head2 Text Construct

You can supply a string to Text Construct parameters, which will be used as the HTML content of the element.

FIXME text/html/xhtml

=head2 Person Construct

You can supply a string to Person Construct parameters, which will be used as the name of the person. The full range of details that can be provided by passing a hash instead of a string is as follows:

=over

=item C<name> (B<required>)

The name of the person.

=item C<email> (optional)

The person's email address.

=item C<uri> (optional)

A URI to distinguish this person. This would usually be a homepage, but need not actually be a dereferencable URL.

=back

=head2 Date Construct

A string denoting a date and time in W3CDTF format. You can generate those using something like

    use POSIX qw( strftime );
    my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;

=head2 Link Construct

You can supply a string to Link Construct parameters, which will be used as the C<href> value of the link. The full range of details that can be provided by passing a hash instead of a string is as follows:

FIXME mention multiplicity

=over

=item C<rel> (optional)

The link relationship. If omitted, defaults to C<alternate> (note that you can only have one alternate link per feed/entry). Other permissible values are C<related>, C<self>, C<enclosure> and C<via>, as well as any URI.

=item C<href> (B<required> URL)

Where the link points to.

=item C<type> (optional)

An advisory media type that provides a hint about the type of the resource pointed to by the link.

=item C<hreflang> (optional)

The language of the resource pointed to by the link, an an RFC3066 language tag.

=item C<title> (optional)

Human-readable information about the link.

=item C<length> (optional)

A hint about the content length in bytes of the resource pointed to by the link.

=back

=head2 Category Construct

FIXME mention multiplicity

You can supply a string to Category Construct parameters, which will be used as the category term. The full range of details that can be provided by passing a hash instead of a string is as follows:

=over

=item C<term> (B<required>)

The category term.

=item C<scheme> (optional)

A URI that identifies a categorization scheme.

It is common to provide the base of some kind of by-category URL here. F.ex., if the weblog C<http://www.example.com/blog/> can be browsed by category using URLs such as C<http://www.example.com/blog/category/personal>, you would supply C<http://www.example.com/blog/category/> as the scheme and, in that case, C<personal> as the term.

=item C<label> (optional)

A human-readable version of the term.

=back



=head1 DIAGNOSTICS

=head2 Warnings

=over

=item C<Missing entry ID, falling back to the alternate link>

You did not supply an identifier for the feed or entry. In this case, the module uses the permalink as the feed's/entry's identifier. It is your responsibility to ensure that the permalink B<NEVER CHANGES>.

You are encouraged to generate a UUID using L<Data::UUID> for the purpose of identifying entries/feeds. It should be stored alongside the resource corresponding to the entry/feed, f.ex. in a column of the article table of your weblog database. To use it as an identifier in the feed, use the C<urn:uuid:########-####-####-####-############> URI form.

=item C<Outputting deprecated Atom 0.3 element '%s' as '%s' according to Atom 1.0>

This module used to generate Atom 0.3 feeds. Atom 0.3 is now deprecated, since Atom 1.0 has been standardised by the IETF, and this module now generates Atom 1.0 feeds. A number of elements from the 0.3 (non)standard have changed names in 1.0.

This module's old interface, which follows Atom 0.3 conventions, will continue to be supported for some time, but you should change your code to use the 1.0 conventions.

=item C<Dropping deprecated Atom 0.3 element '%s' without equivalent in Atom 1.0>

This module used to generate Atom 0.3 feeds. Atom 0.3 is now deprecated, since Atom 1.0 has been standardised by the IETF, and this module now generates Atom 1.0. A small number of features from the 0.3 (non)standard have been removed from Atom 1.0.

Since there is no way to express these concepts in Atom 1.0, this module no longer supports these old features. Please remove their use from your code.

=back


=head2 Errors

=over

=item C<Category without term>

You used a hash without a C<term> key to specify a category. C<term> is a required attribute of a category in Atom.

=item C<Link without href>

You used a hash without a C<href> key to specify a link. C<href> is a required attribute of a link in Atom.

=item C<Too many alternate links>

You used a hash or an array of hashes to define an entry's or feed's links, but more than one of them is an alternate link. (Alternate links are those whose C<rel> attribute is either unspecified or equal to C<alternate>.)

=item C<Missing entry author (required in feeds without author)>

If you did not specify a author for the feed, then every entry in the feed must have an author.

=item C<Missing entry title>, C<Missing feed title>

Titles are required for feeds and entries.

=item C<Missing generator name>

You used a hash without a C<name> key to specify the feed generator. Atom requires that a human-readable name be given for the generator, if the generator is specified.

=item C<Missing person name>

You used a hash without a C<name> key to specify a person. Atom requires a name for every author or contributor mentioned.

=item C<Must pass a filename or filehandle>

You passed something to C<save_file> that's neither a string nor a filehandle.

=item C<No 'src' key allowed in text construct>, C<Type '%s' not allowed in text construct>

You used a hash to specify a text construct, such as a title or entry summary, but specified a C<type> other than C<text>, C<html> or C<xhtml> or specified a C<src> attribute to refer to remote content. Atom only specifies this extended use only for the content of an entry.

=item C<Missing content>

You used a hash without a C<content> key to specify a text construct, such as a title, summary or entry content. Atom requires that such elements have content.

=back


=head1 SEE ALSO

=over

=item * Atom Enabled L<http://www.atomenabled.org/>

=item * W3CDTF Spec L<http://www.w3.org/TR/NOTE-datetime>

=item * RFC 3066 L<http://rfc.net/rfc3066.html>

=item * L<XML::Atom>

=back


=head1 BUGS AND LIMITATIONS

The L</TODO> section is not empty.

Some Atom format features might be missing.

There is currently no support for C<xml:lang> and C<xml:base>. This should be addressed in a future version.

Feeds with extension elements cannot be generated using this module. This is by design.

The module does nothing to ensure that text constructs of type C<xhtml> and entry contents using either that or an XML media type are well-formed. This is by design.

Please report any bugs or feature requests to C<bug-xml-atom-simplefeed@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.


=head1 TODO

=over

=item * Handle all possible media types in C<_content>!

=item * Allow more than one author, and allow for contributors

=item * Reorganize "Constructs" POD section and other parts

=item * Fill in the FIXME POD bits, clear up omissions

=item * Add some knobs so users can twiddle which warnings are emitted

=item * Write reams of unit tests

=back

=head1 AUTHOR

Aristotle Pagaltzis, L<mailto:pagaltzis@gmx.de>

Original version by H. Wade Minter.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Aristotle Pagaltzis. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

use warnings;
use strict;

package XML::Atom::SimpleFeed;

use vars qw( $VERSION );
$VERSION = "0.8_003";

use Carp;
use POSIX qw( strftime );

sub _ATOM_NS      () { 'http://www.w3.org/2005/Atom' }
sub _XHTML_NS     () { 'http://www.w3.org/1999/xhtml' }
sub _PREAMBLE     () { qq(<?xml version="1.0" encoding="us-ascii"?>\n) }
sub _W3C_DATETIME () { '%Y-%m-%dT%H:%M:%SZ' }

sub _DEFAULT_GENERATOR () {
	{
		uri     => 'http://search.cpan.org/dist/XML-Atom-SimpleFeed',
		version => $VERSION,
		name    => 'XML::Atom::SimpleFeed'
	}
}

# named @$self indices
sub _HAVE_AUTHOR    () { 0 }
sub _GLOBAL_UPDATED () { 1 }
sub _FEED_DATA      () { 2 } # this one must always be last

####################################################################
# superminimal XML writer

sub _cdata {
	local $_ = shift;
	s{ ( < ) | ( > ) | ( [&'"\x80-\x{10FFFF}] ) }{ $1 ? '&lt;' : $2 ? '&gt;' : '&#' . ord( $3 ) . ';' }gex;
	return $_;
}

# actually, it's more than just #PCDATA, since this lets angle brackets pass
sub _pcdata {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	local $_ = shift;

	while( -1 < ( my $loc = index $_, "<![CDATA[" ) ) {
		my $end = index $_, "]]>", $loc + 9;
		croak "Incomplete CDATA section" if $end == -1;
		substr $_, $loc, $end - $loc + 3, _cdata substr $_, $loc + 9, $end - $loc - 9;
	}

	s{ ( [\x80-\x{10FFFF}] ) }{ '&#' . ord( $1 ) . ';' }gex;
	return $_;
}

sub _tag {
	my $name = shift;
	my $attr = '';
	if( ref $name eq 'ARRAY' ) {
		my $i = 1;
		while( $i < @$name ) {
			$attr .= ' ' . $name->[ $i ] . '="' . _cdata( $name->[ $i + 1 ] ) . '"';
			$i += 2;
		}
		$name = shift @$name;
	}
	@_ ? "<$name$attr>" . join( '', @_ ) . "</$name>" : "<$name$attr/>";
}

####################################################################

sub _deprecate {
	my ( $arg, $old, $new ) = @_;

	return if not exists $arg->{ $old };

	local $Carp::CarpLevel = $Carp::CarpLevel + 1;

	my $old_val = delete $arg->{ $old };

	if( defined $new and length $new ) {
		$arg->{ $new } = $old_val if not exists $arg->{ $new };
		carp "Outputting deprecated Atom 0.3 element '$old' as '$new' according to Atom 1.0";
	}
	else {
		carp "Dropping deprecated Atom 0.3 element '$old' without equivalent in Atom 1.0";
	}
}

sub _plural(&@) {
	my ( $code, $data ) = @_;
	$code->( ref $data eq 'ARRAY' ? @$data : $data );
}

sub _pairs(&\%@) {
	my ( $code, $hash ) = splice @_, 0, 2;
	map { exists $hash->{ $_ } ? $code->() : () } @_;
}

sub _alternate_link {
	map {
		( not ref $_ ) ? $_
		: ( ref $_ eq 'HASH' and ( not exists $_->{ rel } or $_->{ rel } eq 'alternate' ) ) ? $_->{ href }
		: ()
	} @_;
}

####################################################################

sub _person_construct {
	my $name = shift;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	join '', map {
		my $arg = $_;
		if( ref $arg eq 'HASH' ) {
			_deprecate $arg, url => 'uri';
			croak 'Missing person name' if not exists $arg->{ name };
			_tag $name => _pairs { _tag( $_ => _cdata $arg->{ $_ } ) } %$arg => qw( name email uri );
		}
		else {
			_tag $name => _tag name => $arg;
		}
	} @_;
}

# a lof of the effort here is to omit the type attribute whenever possible
sub _text_construct {
	my $name = shift;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	join '', map {
		my $arg = $_;

		my ( $type, $content );

		if( ref $arg eq 'HASH' ) {
			# FIXME doesn't support @src attribute for $name eq 'content' yet

			$type = exists $arg->{ type } ? $arg->{ type } : 'html';

			croak q{Missing content} unless exists $arg->{ content };

			if( $type eq 'xhtml' ) {
				$content = _pcdata $arg->{ content };

				if( $content !~ /</ ) { # FIXME does this cover all cases correctly?
					$type = 'text';
					$content =~ s/[\n\t]+/ /g;
				}
				else {
					$content = _tag [ div => xmlns => _XHTML_NS ], $content;
				}
			}
			elsif( $type eq 'html' or $type eq 'text' ) {
				$content = _cdata $arg->{ content };
			}
			else {
				croak "Type '$type' not allowed in text construct"
					if $name ne 'content';

				$content = _pcdata $arg->{ content };
			}
		}
		else {
			$type = 'html';
			$content = _cdata $arg;
		}

		if( $type eq 'html' and $content !~ /&/ ) {
			$type = 'text';
			$content =~ s/[\n\t]+/ /g;
		}

		_tag [ $name => $type ne 'text' ? ( type => $type ) : () ], $content;
	} @_;
}

# some effort here to omit the type attribute whenever possible
sub _link {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	join '', map {
		my $arg = $_;

		if( ref $arg eq 'HASH' ) {
			croak 'Link without href' if not exists $arg->{ href };
			my @rel = do {
				local $_ = $arg->{ rel };
				defined and length and $_ ne 'alternate' ? ( rel => $_ ) : ();
			};
			_tag [ link => @rel, _pairs { $_ => $arg->{ $_ } } %$arg => qw( href type title hreflang length ) ];
		}
		else {
			_tag [ link => href => $arg ];
		}
	} @_;
}

sub _category {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	join '', map {
		my $arg = $_;

		if( ref $arg eq 'HASH' ) {
			croak 'Category without term' if not exists $arg->{ term };
			_tag [ category => _pairs { $_ => $arg->{ $_ } } %$arg => qw( term scheme label ) ];
		}
		else {
			_tag [ category => term => $arg ];
		}
	} @_;
}

sub _generator {
	join '', map {
		my $arg = $_;

		if( ref $arg eq 'HASH' ) {
			_deprecate $arg, url => 'uri';
			croak 'Missing generator name' if not exists $arg->{ name };
			my $content = delete $arg->{ name };
			_tag [ generator => _pairs { $_ => $arg->{ $_ } } %$arg => qw( uri version ) ], _cdata( $content );
		}
		else {
			_tag generator => _cdata( $arg );
		}
	} @_;
}

sub new {
	my $class = shift;
	my %arg = @_;

	croak 'Missing feed title' if not exists $arg{ title };

	my @alt;
	@alt = _plural { &_alternate_link } $arg{ link } if exists $arg{ link };

	croak 'Too many alternate links' if @alt > 1;

	if( not exists $arg{ id } ) {
		if( @alt ) {
			carp 'Missing feed ID, falling back to the alternate link';
			$arg{ id } = $alt[ 0 ];
		}
		else {
			croak 'Missing feed ID (and no alternate link available as fallback)';
		}
	}

	_deprecate \%arg, tagline => 'subtitle';
	_deprecate \%arg, copyright => 'rights';
	_deprecate \%arg, modified => 'updated';
	_deprecate \%arg, info => undef;

	my $self = [];

	$self->[ _HAVE_AUTHOR ] = exists $arg{ author };
	$self->[ _GLOBAL_UPDATED ] = $arg{ updated } ||= strftime _W3C_DATETIME, gmtime;

	my $metadata = '';

	$metadata .= _tag id => $arg{ id };
	$metadata .= _text_construct title => $arg{ title };
	$metadata .= _text_construct subtitle => $arg{ subtitle } if exists $arg{ subtitle };
	$metadata .= _plural { &_category } $arg{ category } if exists $arg{ category };
	$metadata .= _plural { &_link } $arg{ link } if exists $arg{ link };
	$metadata .= _person_construct author => $arg{ author } if exists $arg{ author };
	$metadata .= _text_construct rights => $arg{ rights } if exists $arg{ rights };
	$metadata .= _tag updated => $arg{ updated };

	$arg{ generator } = _DEFAULT_GENERATOR if not exists $arg{ generator };
	$metadata .= _generator $arg{ generator } if defined $arg{ generator };

	push @$self, $metadata;

	bless $self, $class;
}

sub add_entry {
	my $self = shift;
	my %arg = @_;

	croak 'Missing entry title' if not exists $arg{ title };

	croak 'Missing entry author (required in feeds without author)'
		if not( $self->[ _HAVE_AUTHOR ] or exists $arg{ author } );

	my @alt;
	@alt = _plural { &_alternate_link } $arg{ link } if exists $arg{ link };

	croak 'Too many alternate links' if @alt > 1;

	if( not exists $arg{ id } ) {
		if( @alt ) {
			carp 'Missing entry ID, falling back to the alternate link';
			$arg{ id } = $alt[ 0 ];
		}
		else {
			croak 'Missing entry ID (and no alternate link available as fallback)';
		}
	}

	_deprecate \%arg, copyright => 'rights';
	_deprecate \%arg, subject => 'category';
	_deprecate \%arg, issued => 'published';
	_deprecate \%arg, modified => 'updated';
	_deprecate \%arg, created => undef;

	my $entry = '';

	$entry .= _tag id => $arg{ id };
	$entry .= _text_construct title => $arg{ title };
	$entry .= _person_construct author => $arg{ author } if exists $arg{ author };
	$entry .= _text_construct rights => $arg{ rights } if exists $arg{ rights };
	$entry .= _plural { &_link } $arg{ link } if exists $arg{ link };
	$entry .= _text_construct summary => $arg{ summary } if exists $arg{ summary };
	$entry .= _text_construct content => $arg{ content } if exists $arg{ content };
	$entry .= _plural { &_category } $arg{ category } if exists $arg{ category };
	$entry .= _tag published => $arg{ published } if exists $arg{ published };
	$entry .= _tag updated => $arg{ updated } || $self->[ _GLOBAL_UPDATED ];

	push @$self, _tag entry => $entry;
}

sub print {
	my $self = shift;
	local $, = local $\ = '';
	# not using $self->as_string to avoid concatenation for a minor perf/mem gain
	print _PREAMBLE, '<feed xmlns="', _ATOM_NS, '">', @$self[ _FEED_DATA .. $#$self ], '</feed>';
}

sub as_string {
	my $self = shift;
	_PREAMBLE . _tag [ feed => xmlns => _ATOM_NS ], @$self[ _FEED_DATA .. $#$self ];
}

sub _is_blessed($) { UNIVERSAL::can( shift, 'can' ) } # only legitimate use of UNIVERSAL::can as function

sub save_file {
	my $self = shift;
	my ( $file ) = @_;

	croak 'Must pass a filename or filehandle'
		if not( defined $file )
		or ( ref $file and ref $file ne 'GLOB' and not ( _is_blessed( $file ) and $file->isa( 'IO::Handle' ) ) )
		or not( length $file );

	die;
}

! ! 'Funky and proud of it.';
