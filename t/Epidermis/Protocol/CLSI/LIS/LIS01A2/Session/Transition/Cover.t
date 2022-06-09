#!/usr/bin/env perl

use Test2::V0;
plan tests => 1;

use lib 't/lib';
use Connection;

use feature qw(state);

use IO::Async::Loop;
use Future::IO::Impl::IOAsync;
use Future::Utils qw(repeat);

use IO::Async::Timer::Periodic;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Simulator';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Client';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEventEmitter' => 'Process::StepEventEmitter';

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state :enum_event);

use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();
use Log::Any qw($log);

subtest "Cover all states" => sub {
	Log::Any::Adapter->set( {
		lexically => \my $lex,
		#category => qr/^main$|^Epidermis::Protocol::CLSI::LIS::LIS01A2::Client/
		},
		'Screen', min_level => 'trace', formatter => sub { $_[1] =~ s/^/  # LOG: /mgr } ) if $ENV{TEST_VERBOSE};

	my $test_conn = Connection->build_test_connection;
	plan skip_all => "Could not create any test connection" unless $test_conn;
	note "Test connection: ", ref $test_conn;
	$test_conn->init;

	my $loop = IO::Async::Loop->new;

	my @transitions;
	my $client_setup = sub {
		my $client_class = Moo::Role->create_class_with_roles(Client, Process::StepEventEmitter);
		my $sess = $client_class->new(
			connection => $test_conn->connection0,
			session_system => SYSTEM_COMPUTER,
			name => 'cli',
		);

		my $step_count = 0;
		$sess->on( step => sub {
			my ($event) = @_;
			++$step_count;
			$log->tracef(
				"[%s] Step %d: %s :: %s",
				$event->emitter->name,
				$step_count,
				$event->state_transition,
				$event->emitter,
			);
			push @transitions, $event->state_transition;
		});

		$sess;
	};

	my $sim_setup = sub {
		my $sim  = Simulator->new(
			session => Session->new(
				connection => $test_conn->connection1,
				session_system => SYSTEM_INSTRUMENT,
				name => 'sim',
			)
		);
		$sim;
	};

	my $sess = $client_setup->();
	my $sim  = $sim_setup->();

	$sess->send_message( LIS01A2::Message->create_message( 'Hello world' ) );

	my @events = (
		[ 'sim-step-n', 4 ],
	);

	my $sim_process_events_f = repeat {
		my ($event_name, $data) = @{ shift @_ };
		$sim->process_event( $event_name, $data );
	} foreach => \@events;

	my $timer = IO::Async::Timer::Periodic->new(
		interval => 1,
		on_tick => sub {
			state $tick = 0;
			print "Timer: @{[ ++$tick ]}\n";
		},
	);
	$loop->later(sub {
		$timer->start;
		$loop->add( $timer );
	});
	$loop->later(sub {
		$loop->await_all(
			$sess->process_until_idle,
			$sim_process_events_f,
		);
		$loop->stop;
	});

	$loop->run;

	is $transitions[-1]->transition, EV_TIMED_OUT, 'timed out';
	is $transitions[-1]->to, STATE_N_IDLE, 'idle';
};

done_testing;
