use strict;
use warnings;

use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing
BEGIN { eval 'use Time::Piece' }

my $bigbang = '<d>1970-01-01T00:00:00Z</d>';

is date_construct( d => 0 ), $bigbang, 'correct RFC 3339 for Unix times';

SKIP: {
	skip 'need Time::Piece', 2 unless ref gmtime;
	is date_construct( d => gmtime 0 ),    $bigbang, 'correct RFC 3339 for Time::Piece objects';
	is date_construct( d => localtime 0 ), $bigbang, '... even if non-UTC';
};

done_testing;
