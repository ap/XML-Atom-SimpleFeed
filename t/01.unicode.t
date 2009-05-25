#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 1;
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
	content   => "\x{FF34}\x{FF25}\x{FF33}\x{FF34} d\xE3t\xE3"
);

like $feed->as_string, qr{<content type="html">&#65332;&#65317;&#65331;&#65332; d&#227;t&#227;</content>}, 'content is properly encoded';
