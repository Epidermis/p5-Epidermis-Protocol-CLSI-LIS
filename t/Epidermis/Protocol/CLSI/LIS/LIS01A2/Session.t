#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Lab::Connection::Serial' => 'Connection::Serial';

use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';
use Try::Tiny;

subtest "Test session" => sub {
SKIP: {
	my $socat = try {
		Socat->new;
	} catch {
		skip $_;
	};

	my $connection = Connection::Serial->new(
		device => $socat->pty0,
		mode => "9600,8,n,1",
	);
	my $session = Session->new( connection => $connection );

	pass;
}
};

done_testing;
