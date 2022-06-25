#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Find::Rule;
use Path::Tiny;
use File::Symlink::Relative;

sub main {
	my $coverage_dir = path( $FindBin::Bin,
		'..',
		't/Epidermis/Protocol/CLSI/LIS/LIS01A2/Session/Transition/Cover'
	);
	my $skel = $coverage_dir->child('test-rel.t.skel');
	die "Skeleton file missing" unless -f $skel;

	my @files = File::Find::Rule
		->file
		->name( '*.data.pl' )
		->in( $coverage_dir );

	symlink_r $skel, $_ for map { $_ =~ s/\Q.data.pl\E$/.t/r } @files;
}

main;
