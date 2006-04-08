#!perl
use strict;
use warnings;
use utf8;

use XML::Atom::SimpleFeed;

my $feed = XML::Atom::SimpleFeed->new(
	title  => 'Example',
	link   => 'http://example.com/log/',
	author => 'Joe Schmoe',
);

$feed->add_entry(
	title => 'Foo',
	link => 'http://example.com/log/foo',
	summary => '<i>Møøse</i>',
	category => 'Fooisms',
);

$feed->add_entry(
	title => 'Bar',
	link => 'http://example.com/log/bar',
	content => {
		type => 'xhtml',
		content => '',
	},
);

$_ = $feed->as_string;

print;
print "\n";
