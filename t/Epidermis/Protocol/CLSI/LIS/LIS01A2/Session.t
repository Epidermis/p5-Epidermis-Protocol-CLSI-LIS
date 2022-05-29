#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use StandardData;

use IO::Async::Loop;
use Future::IO::Impl::IOAsync;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Client';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';
use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat::Role::WithChild';
use Moo::Role ();
use Try::Tiny;

use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

use Log::Any qw($log);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state);

subtest "Test session" => sub {
SKIP: {
	my $socat = try {
		Moo::Role->create_class_with_roles(Socat, WithChild)
			->new(
				$ENV{TEST_VERBOSE}
				? ( message_level => 0, socat_opts => [ qw(-x -v) ] )
				: ()
			);
	} catch {
		skip $_;
	};

	Log::Any::Adapter->set( {
		lexically => \my $lex,
		category => qr/^main$|^Epidermis::Protocol::CLSI::LIS::LIS01A2::Client/ },
		'Screen', min_level => 'trace', formatter => sub { $_[1] =~ s/^/  # LOG: /mgr } ) if $ENV{TEST_VERBOSE};

	my $message = LIS01A2::Message->create_message('Hello, world!');

	my $loop = IO::Async::Loop->new;

	my $open_handle = sub {
		my ($conn) = @_;
		#$conn->handle->blocking(0);
		#$conn->handle->cfmakeraw;
		#$conn->handle->setflag_echo(0);
		#$conn->handle->setflag_clocal( 1 );
	};

	my $run_sm = sub {
		my $loop = shift;
		my $client = shift;
		$log->trace("===> $client");
		$loop->await_all( $client->do_until_neutral_state );
	};

	my $setup_system = sub {
		my ( $connection, $system, $message ) = @_;

		my $client = Client->new(
			connection => $connection,
			session_system => $system,
			name => substr($system, 0, 1),
		);

		$open_handle->( $client->connection );

		my $message_sent_f;
		if( $message ) {
			$client->send_message( $message );
		}

		$run_sm->( IO::Async::Loop->new, $client );
	},

	my @session_f;

	$socat->init;

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $socat->connection0, SYSTEM_COMPUTER, $message );
		},
		setup => [ $socat->connection0->io_async_setup_keep ],
	);

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $socat->connection1, SYSTEM_INSTRUMENT, undef );
		},
		setup => [ $socat->connection1->io_async_setup_keep ],
	);

	$loop->await_all( @session_f );

	pass;
}
};

done_testing;
