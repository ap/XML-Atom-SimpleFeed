use Test::More tests => 1;

require_ok( 'XML::Atom::SimpleFeed' )
	or BAIL_OUT( 'testing pointless if the module won\'t even load' );
