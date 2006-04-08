use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::Atom::SimpleFeed',
    license             => 'perl',
    dist_author         => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
    dist_version_from   => 'lib/XML/Atom/SimpleFeed.pm',
	build_requires => {
		'Test::More'          => 0,
		'Test::Pod'           => 0,
		'Test::Pod::Coverage' => 0,
	},
    add_to_cleanup      => [ 'XML-Atom-SimpleFeed-*' ],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
