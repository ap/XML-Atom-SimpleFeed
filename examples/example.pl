#!perl
use strict;
use warnings;

use XML::Atom::SimpleFeed;

my $feed = XML::Atom::SimpleFeed->new(
	title  => 'Example',
	link   => 'http://example.com/log/',
	author => 'Joe Schmoe',
);

$feed->add_entry(
	title => 'Foo',
	link => 'http://example.com/log/foo',
	category => 'fooisms',
);

$feed->add_entry(
	title => 'Bar',
	link => 'http://example.com/log/bar',
	content => {
		type => 'xhtml',
		content => sub {
			my ( $saxh ) = @_;
			my $e = {
				Name      => 'p',
				LocalName => 'p',
				Prefix    => '',
				NamespaceURI => XML::Atom::SimpleFeed::XHTML_NS,
			};
			$saxh->start_element( $e );
			$saxh->characters( { Data => q"I'm sorry, Dave." } );
			$saxh->end_element( $e );
		}
	},
);

$_ = $feed->as_string;

print;
print "\n";
