#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use StandardData;

use IO::Async::Loop;
use Future::IO::Impl::IOAsync;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

use aliased 'Epidermis::Lab::Connection::Serial' => 'Connection::Serial';

use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';
use Try::Tiny;

use Log::Any::Adapter;
Log::Any::Adapter->set('Screen', min_level => 'trace' );

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system);

subtest "Test session" => sub {
SKIP: {
	my $socat = try {
		Socat->new;
	} catch {
		skip $_;
	};

	my $message = LIS01A2::Message->create_message('Hello, world!');

	my $loop = IO::Async::Loop->new;

	my $cconn = Connection::Serial->new(
		device => $socat->pty0,
		mode => "9600,8,n,1",
	);
	my $csess = Session->new( connection => $cconn, session_system => SYSTEM_COMPUTER );

	my $iconn = Connection::Serial->new(
		device => $socat->pty1,
		mode => "9600,8,n,1",
	);
	my $isess = Session->new( connection => $iconn, session_system => SYSTEM_INSTRUMENT );

	my $message_sent_f = $csess->send_message( $message );

	my $zz = $csess->step;

	pass;
}
};

done_testing;
