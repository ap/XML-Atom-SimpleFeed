use strict; use warnings;

use CPAN::Meta;
use Software::LicenseUtils;
use Pod::Readme::Brief;

sub slurp { open my $fh, '<', $_[0] or die "Couldn't open $_[0] to read: $!\n"; readline $fh }

chdir $ARGV[0] or die "Cannot chdir to $ARGV[0]: $!\n";

my %file;

my $meta = CPAN::Meta->load_file( 'META.json' );

my $license = do {
	my @key = ( $meta->license, $meta->meta_spec_version );
	my ( $class, @ambiguous ) = Software::LicenseUtils->guess_license_from_meta_key( @key );
	die if @ambiguous;
	$class->new( $meta->custom( 'x_copyright' ) );
};

$file{'LICENSE'} = $license->fulltext;

my @source = slurp 'lib/XML/Atom/SimpleFeed.pm';
splice @source, -2, 0, map "$_\n", '', '=head1 AUTHOR', '', $meta->authors;
splice @source, -2, 0, split /(?<=\n)/, "\n=head1 COPYRIGHT AND LICENSE\n\n" . $license->notice;
$file{'lib/XML/Atom/SimpleFeed.pm'} = join '', @source;

die unless -e 'Makefile.PL';
$file{'README'} = Pod::Readme::Brief->new( @source )->render( installer => 'eumm' );

my @manifest = slurp 'MANIFEST';
my %manifest = map /\A([^\s#]+)()/, @manifest;
$file{'MANIFEST'} = join '', sort @manifest, map "$_\n", grep !exists $manifest{ $_ }, keys %file;

for my $fn ( sort keys %file ) {
	unlink $fn if -e $fn;
	open my $fh, '>', $fn or die "Couldn't open $fn to write: $!\n";
	print $fh $file{ $fn };
	close $fh or die "Couldn't close $fn after writing: $!\n";
}
