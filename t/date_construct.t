use strict;
use warnings;

use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing

my $bigbang = '<d>1970-01-01T00:00:00Z</d>';

is date_construct( d => 0 ), $bigbang, 'correct RFC 3339 for Unix times';

SKIP: {
	skip 'missing Time::Piece', 2 unless eval { require Time::Piece };
	is date_construct( d => Time::Piece->gmtime(0) ),    $bigbang, 'correct RFC 3339 for Time::Piece objects';
	is date_construct( d => Time::Piece->localtime(0) ), $bigbang, '... regardless of local timezone';
};

done_testing;
