#!/usr/bin/perl

=head1 NAME

XML::Atom::SimpleFeed - No-fuss generation of Atom syndication feeds

=head1 VERSION

This document describes XML::Atom::SimpleFeed version 0.8_001

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

=item C<generate( [$handler] )>

Serialises the feed using a SAX2 handler. If you don't pass a handler to be used, a default L<XML::SAX::Writer> or L<XML::Genx::SAXWriter> handler will be instantiated, which results in the feed being printed to C<STDOUT>.

=item C<as_string>

Returns the text of the feed as a string. This is a convenience wrapper around C<generate>.

=item C<print>

Outputs the feed to STDOUT. This is just an alias to C<generate>.

=item C<save_file( $file )>

Saves the feed into C<$file>, which can be a filename or filehandle. This is a convenience wrapper that passes a SAX handler instantiated with C<-E<gt>new( Output =E<gt> $file )> to C<generate>.

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


=head2 Internal fatal errors

=over

=item C<Couldn't load default SAX handler>

You did not pass a SAX handler object to C<generate>, but you do not have L<XML::SAX::Writer> or L<XML::Genx::SAXWriter> installed either.

Install one of these modules or make sure your code passes some SAX handler object to C<generate>.

=back


=head1 SEE ALSO

=over

=item * L<XML::SAX::Writer> / L<XML::Genx::SAXWriter>

=item * L<XML::Atom>

=item * Atom Enabled L<http://www.atomenabled.org/>

=item * W3CDTF Spec L<http://www.w3.org/TR/NOTE-datetime>

=item * RFC 3066 L<http://rfc.net/rfc3066.html>

=back


=head1 DEPENDENCIES

You will need some kind of SAX handler to use this module.

If all you want is to output XML, that would be one of the SAX serialiser modules. L<XML::SAX::Writer> is recommended.

=head1 BUGS AND LIMITATIONS

Feeds with extension elements cannot be generated using this module.

Only one author per feed and entry is currently supported and no contributors can be mentioned.

More Atom format features might be missing.

There is currently no support for C<xml:lang> and C<xml:base>. This should be addressed in a future version.

No bugs have been reported.

Please report any bugs or feature requests to C<bug-xml-atom-simplefeed@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.


=head1 DEVELOPMENT NOTES

=over

=item * Fill in the FIXME POD bits

=item * Write reams of unit tests

=item * Add some knobs so users can twiddle which warnings are emitted

=item * Find a way to stream output

This is difficult with the current interface, since C<print>, C<as_string> etc. only get called at the very end of the object's lifecycle. To stream the output, the SAX handler used would have to be supplied at the very beginning instead. How to reconcile the two?

=item * Possibly switch to L<Class::Std>

But that may not be necessary if I find a good solution for streaming output, since that would obviate the need for keeping any internal state. That would also make the module more parsimonious with memory; not that that seems likely to be a great concern for a module generating Atom feeds.

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
$VERSION = "0.8_001";

use Carp;
use POSIX qw( strftime );

# constants
sub ATOM_NS    () { 'http://www.w3.org/2005/Atom' }
sub XHTML_NS   () { 'http://www.w3.org/1999/xhtml' }
sub W3C_DATETIME () { '%Y-%m-%dT%H:%M:%SZ' }

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

sub _person_construct {
	my $arg = shift || return;

	if( ref $arg eq 'HASH' ) {
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		croak 'Missing person name' if not exists $arg->{ name };
		return $arg;
	}
	else {
		return { name => $arg };
	}
}

sub _link_construct {
	my $arg = shift || return;

	if( ref $arg eq 'HASH' ) {
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		croak 'Link without href' if not exists $arg->{ href };
		return $arg;
	}
	else {
		return { href => $arg };
	}
}

sub _category_construct {
	my $arg = shift || return;

	if( ref $arg eq 'HASH' ) {
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		croak 'Category without term' if not exists $arg->{ term };
		return $arg;
	}
	else {
		return { term => $arg };
	}
}

sub _text_construct {
	my $arg = shift || return;

	if( ref $arg eq 'HASH' ) {
		local $Carp::CarpLevel = $Carp::CarpLevel + 1;
		croak "Type '$arg->{type}' not allowed in text construct"
			if not grep $_ eq $arg->{ type }, qw( text html xhtml );
		croak q{No 'src' key allowed in text construct}
			if exists $arg->{ src };
	}

	return _content_construct( $arg );
}

sub _content_construct {
	my $arg = shift || return;

	if( ref $arg eq 'HASH' ) {
		croak q{Missing content} unless $arg->{ content };
		return $arg;
	}
	else {
		return { type => 'html', content => $arg };
	}
}

sub _links {
	my ( $arg ) = @_;

	local $Carp::CarpLevel = $Carp::CarpLevel + 1;

	my @link;

	if( ref $arg eq "ARRAY" ) { @link = map _link_construct( $_ ), @$arg }
	else { $link[ 0 ] = _link_construct( $arg ) if defined $arg }

	my @alt = grep { not( exists $_->{ rel } ) or $_->{ rel } eq 'alternate' } @link; 
	croak 'Too many alternate links' if @alt > 1;

	return \@link;
}

sub _categories {
	my ( $arg ) = @_;

	local $Carp::CarpLevel = $Carp::CarpLevel + 1;

	my @cat;

	if( ref $arg eq "ARRAY" ) { @cat = map _category_construct( $_ ), @$arg }
	else { $cat[ 0 ] = _category_construct( $arg ) if defined $arg }

	return \@cat;
}

my (
	%id, %title, %subtitle, %author, %rights, %generator, %links, %summary,
	%content, %categories, %published, %updated, %entries,
);

sub new {
	my $class = shift;
	my %arg = @_;

	_deprecate \%arg, tagline => 'subtitle';
	_deprecate \%arg, copyright => 'rights';
	_deprecate \%arg, modified => 'updated';
	_deprecate \%arg, info => undef;

	_deprecate $arg{ author }, url => 'uri' if ref $arg{ author } eq 'HASH';
	_deprecate $arg{ generator }, url => 'uri' if ref $arg{ generator } eq 'HASH';

	my $self = do { local $_ = 1; \$_ }; # get dummy reference

	$id        { 0+$self } = $arg{ id } if exists $arg{ id };
	$title     { 0+$self } = _text_construct( $arg{ title } ) || croak 'Missing feed title';
	$subtitle  { 0+$self } = _text_construct $arg{ subtitle } if exists $arg{ subtitle };
	$categories{ 0+$self } = _categories( $arg{ category } );
	$links     { 0+$self } = _links $arg{ link };
	$author    { 0+$self } = _person_construct $arg{ author } if exists $arg{ author };
	$rights    { 0+$self } = _text_construct $arg{ rights } if exists $arg{ rights };
	$updated   { 0+$self } = $arg{ updated } || strftime W3C_DATETIME, gmtime;
	$generator { 0+$self } = exists $arg{ generator } ? $arg{ generator } : {
		uri     => 'http://search.cpan.org/dist/XML-Atom-SimpleFeed',
		version => $VERSION,
		name    => 'XML::Atom::SimpleFeed'
	};

	if( not defined $id{ 0+$self } ) {
		carp 'Missing entry ID, falling back to the alternate link';
		for( @{ $links{ 0+$self } } ) {
			next if exists $_->{ rel } and $_->rel ne 'alternative';
			$id{ 0+$self } = $_->{ href };
			last;
		}
	}

	croak 'Missing generator name'
		if exists $generator{ 0+$self } and not exists $generator{ 0+$self }{ name };

	bless $self, $class;
}

sub add_entry {
	my $self = shift;
	my %arg = @_;

	_deprecate \%arg, copyright => 'rights';
	_deprecate \%arg, subject => 'category';
	_deprecate \%arg, issued => 'published';
	_deprecate \%arg, modified => 'updated';
	_deprecate \%arg, created => undef;

	_deprecate $arg{ author }, url => 'uri' if ref $arg{ author } eq 'HASH';

	my $entry = do { local $_ = 1; \$_ }; # get dummy reference

	$id        { 0+$entry } = $arg{ id };
	$title     { 0+$entry } = _text_construct( $arg{ title } ) || croak 'Missing entry title';
	$author    { 0+$entry } = _person_construct $arg{ author } if exists $arg{ author };
	$rights    { 0+$entry } = _text_construct $arg{ rights } if exists $arg{ rights };
	$links     { 0+$entry } = _links $arg{ link };
	$summary   { 0+$entry } = _text_construct $arg{ summary } if exists $arg{ summary };
	$content   { 0+$entry } = _content_construct $arg{ content } if exists $arg{ content };
	$categories{ 0+$entry } = _categories( $arg{ category } );
	$published { 0+$entry } = $arg{ published } if exists $arg{ published };
	$updated   { 0+$entry } = $arg{ updated } || $updated{ 0+$self };

	if( not defined $id{ 0+$entry } ) {
		carp 'Missing entry ID, falling back to the alternate link';
		for( @{ $links{ 0+$entry } } ) {
			next if exists $_->{ rel } and $_->rel ne 'alternative';
			$id{ 0+$entry } = $_->{ href };
			last;
		}
	}

	croak 'Missing entry author (required in feeds without author)'
		if not ( exists $author{ 0+$entry } or exists $author{ 0+$self } );

	push @{ $entries{ 0+$self } }, $entry;
}

sub _start_element {
	my ( $h, $element, $attr ) = @_;

	my %element = (
		Name      => $element,
		LocalName => $element,
		Prefix    => '',
		NamespaceURI => ATOM_NS,
	);

	if( defined $attr ) {
		$element{ Attributes } = {
			map { sprintf( '{%s}%s', ATOM_NS, $_ ) => +{
				Name      => $_,
				Prefix    => '',
				LocalName => $_,
				Value     => $attr->{ $_ },
			} } keys %$attr,
		};
	}

	$h->start_element( \%element );

	delete $element{ Attributes };

	return \%element;
}

sub _element {
	# $attr is optional
	my ( $h, $element, $attr, $data ) = @_;
	( $data, $attr ) = ( $attr, undef ) if ref $attr ne 'HASH';

	my $e = _start_element( $h, $element, $attr );

	$h->characters( { Data => $data } ) if defined $data;

	$h->end_element( $e );
}

sub _text_construct_element {
	my ( $h, $element, $txtconst ) = @_;

	my %attr = %$txtconst;
	my $content = delete $attr{ content }; 

	my $e = _start_element( $h, $element, \%attr );

	if( defined $content ) {
		if( $attr{ type } eq 'xhtml' and ref $content eq 'CODE' ) {
			$h->start_prefix_mapping( { Prefix => '', NamespaceURI => XHTML_NS } );
			my %element = ( Name => 'div', LocalName => 'div', Prefix => '', NamespaceURI => XHTML_NS, );
			$h->start_element( \%element );
			$content->( $h );
			$h->end_element( \%element );
			$h->end_prefix_mapping( { Prefix => '', NamespaceURI => XHTML_NS } );
		}
		elsif( $attr{ type } =~ m{ [/+] xml \z }imsx and ref $content eq 'CODE' ) {
			$content->( $h );
		}
		else {
			$h->characters( { Data => $content } );
		}
	}

	$h->end_element( $e );
}

sub _default_handler {
	my $self = shift;
	eval{ require XML::SAX::Writer } ? XML::SAX::Writer->new( @_ )
	: eval{ require XML::Genx::SAXWriter } ? XML::Genx::SAXWriter->new( @_ )
	: die q"Couldn't load default SAX handler";
}

sub generate {
	my $self = shift;

	my ( $h ) = @_;

	$h ||= $self->_default_handler();

	$h->start_document();
	$h->start_prefix_mapping( { Prefix => '', NamespaceURI => ATOM_NS } );
	my $_feed = _start_element( $h, 'feed' );

	_element( $h, id => $id{ 0+$self } );
	_text_construct_element( $h, title => $title{ 0+$self } );

	_text_construct_element( $h, subtitle => $subtitle{ 0+$self } )
		if exists $subtitle{ 0+$self };

	_element( $h, category => $_ )
		for @{ $categories{ 0+$self } };

	if( exists $author{ 0+$self } ) {
		my $au = $author{ 0+$self };
		my $_author = _start_element( $h, 'author' );
		_element( $h, $_, $au->{ $_ } ) for keys %$au;
		$h->end_element( $_author );
	}

	_text_construct_element( $h, rights => $rights{ 0+$self } )
		if exists $rights{ 0+$self };

	_element( $h, link => $_ )
		for @{ $links{ 0+$self } };

	if( exists $generator{ 0+$self } ) {
		my %c = %{ $generator{ 0+$self } };
		my $data = delete $c{ name };
		_element( $h, generator => \%c, $data );
	}

	_element( $h, updated => $updated{ 0+$self } );

	for my $entry ( @{ $entries{ 0+$self } } ) {
		my $_entry = _start_element( $h, 'entry' );

		_element( $h, id => $id{ 0+$entry } );
		_text_construct_element( $h, title => $title{ 0+$entry } );

		_element( $h, link => $_ )
			for @{ $links{ 0+$entry } };

		_text_construct_element( $h, summary => $summary{ 0+$entry } )
			if exists $summary{ 0+$entry };
		_text_construct_element( $h, content => $content{ 0+$entry } )
			if exists $content{ 0+$entry };

		_element( $h, category => $_ )
			for @{ $categories{ 0+$entry } };

		if( exists $author{ 0+$entry } ) {
			my $au = $author{ 0+$entry };
			my $_author = _start_element( $h, 'author' );
			_element( $h, $_, $au->{ $_ } ) for keys %$au;
			$h->end_element( $_author );
		}

		_text_construct_element( $h, rights => $rights{ 0+$entry } )
			if exists $rights{ 0+$entry };
		_element( $h, published => $published{ 0+$entry } )
			if exists $published{ 0+$entry };
		_element( $h, updated => $updated{ 0+$entry } );

		$h->end_element( $_entry );
	}

	$h->end_element( $_feed );
	$h->end_prefix_mapping( { Prefix => '', NamespaceURI => ATOM_NS } );
	$h->end_document();
}

# alias ->print to ->generate
*print = *print = \&generate;

sub save_file {
	my $self = shift;
	my ( $file ) = @_;

	croak 'Must pass a filename or filehandle'
		if not( defined $file )
		or ( ref $file and ref $file ne 'GLOB' and not UNIVERSAL::isa( $file, 'IO::Handle' ) )
		or not( length $file );

	$self->generate( $self->_default_handler( Output => $file ) );
}

sub as_string {
	my $self = shift;
	my $str;
	$self->generate( $self->_default_handler( Output => \$str ) );
	return $str;
}

sub DESTROY {
	my $self = shift;

	for my $entry ( @{ $entries{ 0+$self } } ) {
		delete $id        { 0+$entry };
		delete $title     { 0+$entry };
		delete $author    { 0+$entry };
		delete $rights    { 0+$entry };
		delete $links     { 0+$entry };
		delete $summary   { 0+$entry };
		delete $content   { 0+$entry };
		delete $categories{ 0+$entry };
		delete $published { 0+$entry };
		delete $updated   { 0+$entry };
	}

	delete $id        { 0+$self };
	delete $title     { 0+$self };
	delete $links     { 0+$self };
	delete $updated   { 0+$self };
	delete $subtitle  { 0+$self };
	delete $rights    { 0+$self };
	delete $author    { 0+$self };
	delete $generator { 0+$self };
	delete $categories{ 0+$self };
	delete $entries   { 0+$self };

	return;
}

'Funky and proud of it.';
