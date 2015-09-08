use strict;
use warnings;

use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing
BEGIN { eval 'use Time::Piece' }

is person_construct( author => 'John Doe &' ), '<author><name>John Doe &#38;</name></author>', 'author names are escaped';
is person_construct( author => "John Doe \x{263A}" ), '<author><name>John Doe &#9786;</name></author>', 'non-ASCII author names are encoded';

is date_construct( updated => 0 ), '<updated>1970-01-01T00:00:00Z</updated>', 'correct RFC 3339 for Unix times';
SKIP: {
	skip 'need Time::Piece', 2 unless ref gmtime;
	is   date_construct( d => gmtime 0 ), '<d>1970-01-01T00:00:00Z</d>', 'correct RFC 3339 for Time::Piece objects';
	like date_construct( d => localtime 0 ), qr!\A<d>1970-01-01T[0-9]{2}:[0-9]{2}:00Z</d>\z!, '... even if non-UTC';
};

done_testing;
