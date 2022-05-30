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
use aliased 'Epidermis::Lab::Test::Connection::Pipely';
use Moo::Role ();
use Try::Tiny;

use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

use Log::Any qw($log);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state);

subtest "Test session" => sub {
SKIP: {
	my $test_conn;
	for my $try (
		[ Socat => sub {
			Moo::Role->create_class_with_roles(Socat, WithChild)
				->new(
					$ENV{TEST_VERBOSE}
					? ( message_level => 0, socat_opts => [ qw(-x -v) ] )
					: ()
				);
		}],
		[ Pipely => sub {
			Pipely->new;
		}]
	) {
		my ($name, $code) = @$try;
		my $conn = try {
			note "Trying test connection $name";
			$code->();
		} catch {
			note "Error with $name test connection: $_";
		};
		if( $conn ) {
			$test_conn = $conn;
			last;
		} else {
			next;
		}
	}

	skip "Could not create any test connection" unless $test_conn;

	note "Test connection: ", ref $test_conn;

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
		my $step_count = 0;
		$client->on( step => sub {
			my ($event) = @_;
			++$step_count;
			$log->tracef(
				"[%s] Step %d: %s :: %s",
				$event->emitter->name,
				$step_count,
				$event->state_transition,
				$event->emitter,
			);
		});
		$loop->await_all( $client->process_until_idle );
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

	$test_conn->init;

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $test_conn->connection0, SYSTEM_COMPUTER, $message );
		},
		setup => [ $test_conn->connection0->io_async_setup_keep ],
	);

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $test_conn->connection1, SYSTEM_INSTRUMENT, undef );
		},
		setup => [ $test_conn->connection1->io_async_setup_keep ],
	);

	$loop->await_all( @session_f );

	pass;
}
};

done_testing;
