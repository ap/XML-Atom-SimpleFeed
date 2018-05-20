requires 'perl', '5.008001';
requires 'strict';
requires 'warnings';
requires 'Carp';
requires 'Encode';
requires 'POSIX';

on test => sub {
	requires 'Test::More';
	requires 'utf8';
};

# vim: ft=perl
