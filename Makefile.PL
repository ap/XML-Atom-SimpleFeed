use 5.0005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::Atom::SimpleFeed',
    VERSION_FROM      => 'lib/XML/Atom/SimpleFeed.pm', # finds $VERSION
    PREREQ_PM         => {Test::More => 0, XML::Simple => 2.10}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/Atom/SimpleFeed.pm', # retrieve abstract from module
       AUTHOR         => 'H Wade Minter <minter@lunenburg.org>') : ()),
);
