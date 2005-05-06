#!/usr/bin/perl

# SVN ID: $Id: SimpleFeed.pm 38 2005-05-06 15:10:02Z minter $

package XML::Atom::SimpleFeed;

$VERSION = "0.7";

use warnings;
use strict;

use XML::Simple;
use Carp;

sub new
{
    my ( $class, %arg ) = @_;
    my $ref = { feed => [] };
    my @entries;

    $ref->{feed}[0]{'xmlns:dc'} = 'http://purl.org/dc/elements/1.1/';
    $ref->{feed}[0]{'xmlns'}    = 'http://purl.org/atom/ns#';
    $ref->{feed}[0]{version}    = '0.3';

    $ref->{feed}[0]{title} = _set_element_attrs( $arg{title} )
      || croak 'Atom feeds must have a title.';

    $ref->{feed}[0]{generator}[0] = $arg{generator}
      || {
        url     => 'http://search.cpan.org/dist/XML-Atom-SimpleFeed',
        version => $XML::Atom::SimpleFeed::VERSION,
        content => 'XML::Atom::SimpleFeed'
      };

    #    $ref->{feed}[0]{'xml:lang'} = 'en';    # FIXME
    $ref->{feed}[0]{modified}[0] = $arg{modified} || _generate_now_w3cdtf();
    $ref->{feed}[0]{tagline}[0] = _set_element_attrs( $arg{tagline} )
      if $arg{tagline};
    $ref->{feed}[0]{copyright}[0] = _set_element_attrs( $arg{copyright} )
      if $arg{copyright};
    $ref->{feed}[0]{id}[0] = $arg{id} if $arg{id};

    if ( ref $arg{link} eq "HASH" )
    {

        # A single hashref can be used, but rel must be alternate.
        croak 'A single link must have rel=alternate, a href, and a type'
          unless ( $arg{link}->{href}
            && $arg{link}->{type}
            && ( $arg{link}->{rel} eq "alternate" ) );
        $ref->{feed}[0]{link}[0] = $arg{link};
    }
    elsif ( ref $arg{link} eq "ARRAY" )
    {

     # An array of hashrefs can be used, but at least one must be rel=alternate.
        my $found_alternate = 0;
        foreach my $href ( @{ $arg{link} } )
        {
            next unless ref $href eq "HASH";
            $found_alternate++ if ( $href->{rel} eq "alternate" );
            if ( $href->{rel} && $href->{href} && $href->{type} )
            {
                push( @{ $ref->{feed}[0]{link} }, $href );
            }
            else
            {
                croak 'The link must specify the rel, href, and type.';
            }
        }
        croak 'At least one of your links must be of type rel = alternate.'
          unless $found_alternate;
    }
    elsif ( $arg{link} )
    {

   # A simple string can be used, and will be taken as the href of rel=alternate
        $ref->{feed}[0]{link}[0] =
          { rel => 'alternate', href => $arg{link}, type => 'text/html' };
    }
    else
    {
        croak 'Atom feeds must have a link to an alternate representation.';
    }

    if ( $arg{author}->{name} )
    {
        %{ $ref->{feed}[0]{author}[0] } =
          map { $_ => [ $arg{author}->{$_} ] } keys( %{ $arg{author} } );
    }

    $ref->{feed}[0]{entry} = [];

    bless $ref, $class;
}

sub add_entry
{
    my ( $self, %arg ) = @_;

    my %entry;

    if ( ref $arg{link} eq "HASH" )
    {
        croak 'A single link must have rel=alternate, a href, and a type'
          unless ( $arg{link}->{href}
            && $arg{link}->{type}
            && ( $arg{link}->{rel} eq "alternate" ) );
        $entry{link}->[0] = $arg{link};
    }
    elsif ( ref $arg{link} eq "ARRAY" )
    {

     # An array of hashrefs can be used, but at least one must be rel=alternate.
        my $found_alternate = 0;
        foreach my $href ( @{ $arg{link} } )
        {
            next unless ref $href eq "HASH";
            $found_alternate++ if ( $href->{rel} eq "alternate" );
            if ( $href->{rel} && $href->{href} && $href->{type} )
            {
                push( @{ $entry{link} }, $href );
            }
            else
            {
                croak 'The link must specify the rel, href, and type.';
            }
        }
        croak 'At least one of your links must be of type rel = alternate.'
          unless $found_alternate;
    }
    elsif ( $arg{link} )
    {
        $entry{link}->[0] =
          { rel => 'alternate', href => $arg{link}, type => 'text/html' };
    }
    else
    {
        croak
          'Atom feed entries must have a link to an alternate representation.';
    }

    $entry{title}->[0] = _set_element_attrs( $arg{title} )
      || croak 'Atom feed entries must have a title.';

    if ( $arg{author} )
    {
        croak 'Atom feed entry authors must have a name given.'
          unless $arg{author}->{name};
        %{ $entry{author} } =
          map { $_ => [ $arg{author}->{$_} ] }
          keys( %{ $arg{author} } );
    }
    elsif ( $self->{feed}[0]{author} )
    {
        $entry{author} = undef;
    }
    else
    {
        croak
          'Atom feed entries must have an author if none was given for the feed itself.';
    }

    $entry{modified}->[0] = $arg{modified} || _generate_now_w3cdtf();
    $entry{issued}->[0]   = $arg{issued}   || _generate_now_w3cdtf();
    $entry{id}->[0]       = $arg{id}
      || _generate_entry_id( $entry{link}[0]->{href}, $entry{issued}->[0] );

    $entry{created}->[0] = _set_element_attrs( $arg{created} ) if $arg{created};
    $entry{summary}->[0] = _set_element_attrs( $arg{summary} ) if $arg{summary};

    $entry{content}->[0] = _set_element_attrs( $arg{content} ) if $arg{content};

    $entry{'dc:subject'}->[0] = $arg{subject} if $arg{subject};

    push( @{ $self->{feed}[0]{entry} }, \%entry );

}

sub print
{
    my $self = shift;
    my $xml  = as_string($self);

    print $xml;
}

sub save_file
{
    my $self = shift;
    my $arg  = shift
      || croak 'Usage: '
      . __PACKAGE__
      . '::save_file( $self, $fh_or_filename )';
    my $fh;

    if ( ref $arg eq "GLOB" )
    {
        $fh = $arg;
    }
    else
    {
        open( $fh, ">", $arg ) || return;
    }

    my $content = as_string($self);
    print $fh $content;

    close($fh) || return if $arg != $fh;

    return 1;
}

sub as_string
{
    my $self = shift;

    my $xml = XMLout(
        $self,
        SuppressEmpty => 1,
        RootName      => 'feed',
        KeepRoot      => 1,
        AttrIndent    => 1
    );
    return $xml;
}

sub _set_element_attrs
{
    my $arg = shift || return;
    my %element;

    if ( ref $arg eq "HASH" )
    {
        die 'Internal error: dude, where\'s my content?' unless $arg->{content};
        %element =
          map { $_ => [ $arg->{$_} ] }
          keys( %{$arg} );
    }
    else
    {
        %element = ( mode => 'escaped', type => 'text/html', content => $arg );
    }

    return \%element;
}

sub _generate_now_w3cdtf
{
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = gmtime;
    $year += 1900;
    $mon++;
    my $timestring = sprintf( "%4d-%02d-%02dT%02d:%02d:%02dZ",
        $year, $mon, $mday, $hour, $min, $sec );
    return ($timestring);
}

sub _generate_entry_id
{

    # Generate a UUID for a feed based on Mark Pilgrim's method at
    # http://diveintomark.org/archives/2004/05/28/howto-atom-id

    my ( $link, $modified ) = @_;

    $link =~ s#^.*?://(.*)#$1#;
    $link =~ s|#|/|g;

    $modified =~ /^(\d+-\d+-\d+)/;
    my $datestring = $1;

    $link =~ s#^(.*?)/(.*)$#tag:$1,$datestring:/$2#;
    $link =~ s#/#%2F#g;

    return ($link);
}

1;

__END__

=head1 NAME

XML::Atom::SimpleFeed - Generate simple Atom syndication feeds

=head1 SYNOPSIS

    use XML::Atom::SimpleFeed;

    # Create the feed object
    my $atom = XML::Atom::SimpleFeed->new(
        title    => "My Atom Feed",
        link     => "http://www.example.com/blog/",
        modified => "2005-02-18T15:00:00Z",
        tagline => "This is an example feed.  Nothing to see here.  Move along."
    );

    # Add an entry to the feed
    $atom->add_entry(
        title    => "A Sample Entry",
        link     => "http://www.example.com/blog/entries/1234",
        author   => { name => "J. Random Hacker", email => 'jrh@example.com' },
        modified => "2005-02-18T16:45:00Z",
        issued   => "2005-02-18T15:30:00Z",
        content  => "This is the body of the entry"
    );

    # Add a more complicated entry
    $atom->add_entry(
        title => 'A more complicated example.',
        link  => [
            {
                rel  => 'alternate',
                href => 'http://www.example.com/blog/entries/1337',
                type => 'text/html'
            },
            {
                rel  => 'start',
                href => 'http://www.example.com/blog/entries/1',
                type => 'text/html'
            }
        ],
        author => {
            name  => 'Foo Bar',
            url   => 'http://www.example.com/foobar/',
            email => 'foo@example.com'
        },

        copyright => 'Copyright 2005 by Foo Bar Inc.',
        generator => 'Elite Blogs LLP',
        subject   => 'Technology',
        content   => 'I have nothing to say now.'
    );

    # Print out the feed
    $atom->print;


=head1 DESCRIPTION

This module exists to generate basic Atom syndication feeds.  While it does not provide a full, object-oriented interface into all the nooks and crannies of Atom feeds, an Atom parser, or an Atom client API, it should be useful for people who want to generate basic, valid Atom feeds of their content quickly and easily. 

The module should, by default, allow you to produce valid Atom feeds by supplying simple strings to fill in most structures.  However,  you can provide more advanced structures (hashes, arrays) to do more advanced things if you need to.  Check the docs to see which options take more complex datatypes.

=head1 METHODS

=over 4

=item my $atom = XML::Atom::SimpleFeed->new(%args);

This creates a new XML::Atom::SimpleFeed objects with the supplied parameters.  The parameters are supplied as a hash.  Some parameters are required, some are optional.  For many fields, the default is to encode the item as escaped HTML, so that you don't accidentally produce invalid feeds by including an HTML tag.  They are:

=over

=item * title

REQUIRED (string/hash).  The title of the Atom feed.  If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=item * link

REQUIRED (string/hash/array).  The URL link of the Atom feed.  Normally points to the home page of the resource you are syndicating.  If supplied as a string, it will be given the parameters rel=alternate, type=text/html.  If supplied as a hash, you must provide the keys for rel=alternate, the href, and the type ( such as link => { rel=>'alternate', href=>'http://www.example.com/', type=>'text/plain'} ).  If supplied as an array, must be an array of hashes, each hash providing the rel, href, and type, and at least one being rel=alternate.

=item * modified

OPTIONAL (string).  The date the feed was last modified in W3CDTF format.  This is a REQUIRED element in the Atom spec, but if you do not supply it, the current date and time will be used.

=item * tagline

OPTIONAL (string/hash).  A description or tagline for the feed.  If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=item * generator

OPTIONAL (string/hash).  The software agent used to generate the feed.  Can be supplied as a string, or a hash providing a URL, version, and content.  If not supplied, will be set to the hash { url => 'http://search.cpan.org/dist/XML-Atom-SimpleFeed', version => $XML::Atom::SimpleFeed::VERSION, content => 'XML::Atom::SimpleFeed' }

=item * copyright

OPTIONAL (string/hash).  The copyright string for the feed.  If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=item * info

OPTIONAL (string/hash).  A human-readable explanation of the feed format itself.  If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=item * id 

OPTIONAL (string). A permanent, globally unique identifier for the feed.

=item * author 

OPTIONAL (hash).  An anonymous hash of information about the author of the feed.  If this element exists, it will be used to provide author information for a feed entry, if no author information was provided for the entry.  The author hash contains the following information:

=over

=item * name

REQUIRED (string).  The name of the author ("J. Random Hacker")

=item * email

OPTIONAL (string).  The email address of the author ("jrh@example.com")

=item * url

OPTIONAL (string).  The URL of the author ("http://www.example.com/jrh/")

=back

=back

=item $atom->add_entry(%args);

This method adds an entry into the atom feed.  Its arguments are supplied as a hash, with the following keys:

=over

=item * title

REQUIRED (string/hash).  The title of the entry. If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=item * link

REQUIRED (string/hash/array).  The URL link of the entry itself.  Should be unique to ensure valid feeds.  If supplied as a string, it will be given the parameters rel=alternate, type=text/html.  If supplied as a hash, you must provide the keys for rel=alternate, the href, and the type ( such as link => { rel=>'alternate', href=>'http://www.example.com/', type=>'text/plain'} ).  If supplied as an array, must be an array of hashes, each hash providing the rel, href, and type, and at least one being rel=alternate.

=item * author

OPTIONAL/REQUIRED (hash).  A hash of information about the author of the entry.  You may only omit this if you have specified author information for the feed itself.

=over

=item * name

REQUIRED (string).  The name of the author ("J. Random Hacker")

=item * email

OPTIONAL (string).  The email address of the author ("jrh@example.com")

=item * url

OPTIONAL (string).  The URL of the author ("http://www.example.com/jrh/")

=back

=item * id

OPTIONAL (string).  Optional with a caveat.  This is the globally unique identifier for the feed.  It should be a string that does not change.  If the id is not provided, the module will attempt to construct one via the link parameter, based on the Mark Pilgrim method.  For more information about generating unique ids in Atom, see L<http://diveintomark.org/archives/2004/05/28/howto-atom-id>

=item * issued

OPTIONAL (string).  The date and time the entry was first published, in W3CDTF format.  A REQUIRED part of the Atom spec.  Should be set once and not changed (if the feed changes, use the modified parameter below).  If this parameter is not provided, the current date and time will be used.

=item * modified

OPTIONAL (string).  The date and time the entry was last modified, in W3CDTF format.  A REQUIRED part of the Atom spec.  This is the date you will change if the contents of the feed are modified.  If this parameter is not provided, the current date and time will be used.

=item * created

OPTIONAL (string).  The date and time the entry was created (differs from "issued" and "modified"), in W3CDTF format.  May often be, but is not necessarily, the same time the entry was issued.

=item * summary

OPTIONAL (string/hash).  A short summary of the entry.  If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=item * subject

OPTIONAL (string).  The subject of the entry.  Part of Dublin Core.

=item * content

OPTIONAL (string/hash).  The actual, honest-to-goodness, body of the entry.  If supplied as a string, it will be equivalent to the hash { mode => 'escaped', type => 'text/html', content => $string }.  You can override this by supplying an anonymous hash with those fields defined.

=back

=item $atom->as_string();

Returns the text of the atom feed as a scalar.

=item $atom->print();

Outputs the full atom feed to STDOUT;

=item $atom->save_file($file);

Saves the full atom feed into the file referenced by $file.  If $file is a open filehandle, the output will go there.  Otherwise, $file is taken to be the name of a file which should be written to. Returns true on success.

=head1 BUGS

Most likely does not implement all the useful features of an Atom feed.  Comments and patches welcome!

=head1 SEE ALSO

XML::Atom L<http://search.cpan.org/dist/XML-Atom/>

XML::Simple L<http://search.cpan.org/dist/XML-Simple/>

Atom Enabled L<http://www.atomenabled.org/>

W3CDTF Spec L<http://www.w3.org/TR/NOTE-datetime>

=head1 AUTHOR

H. Wade Minter, E<lt>minter@lunenburg.orgE<gt>
L<http://www.lunenburg.org/>

=head1 CREDITS

Aristotle Pagaltzis, for suggestions on making the module much better behaved.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by H. Wade Minter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
