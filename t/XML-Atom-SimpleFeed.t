# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Atom-SimpleFeed.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('XML::Atom::SimpleFeed') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $feed;

ok( $feed = XML::Atom::SimpleFeed->new(title=>'Test Title', link=>'http://www.example.com/'), "create feed" ) or diag ("Could not create feed object");
ok($feed->add_entry(title=>'Test Entry', link=>'http://www.example.com/1234', author=>{name=>'J. Random Hacker'}), 'add feed entry') or diag ("Could not add an entry to the feed");
ok($feed->print, 'print feed') or diag ("Could not print feed");
