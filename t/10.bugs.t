#!/usr/bin/perl
use warnings;
use strict;
use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More tests => 2;

is person_construct( author => 'John Doe &' ), '<author><name>John Doe &#38;</name></author>', 'author names are escaped';
is person_construct( author => "John Doe \x{263A}" ), '<author><name>John Doe &#9786;</name></author>', 'non-ASCII author names are encoded';
