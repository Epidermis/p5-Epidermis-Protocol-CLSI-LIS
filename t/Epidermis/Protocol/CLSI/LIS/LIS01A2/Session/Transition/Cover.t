#!/usr/bin/env perl

use lib 't/lib';
use Test2::Roo;
with 'Test::SessionSim';

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

use feature qw(state);

use IO::Async::Timer::Periodic;

use Future::Utils qw(repeat);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state :enum_event);

use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

test "Cover all states" => sub {
	my $self = shift;
	Log::Any::Adapter->set( {
		lexically => \my $lex,
		#category => qr/^main$|^Epidermis::Protocol::CLSI::LIS::LIS01A2::Client/
		},
		'Screen', min_level => 'trace', formatter => sub { $_[1] =~ s/^/  # LOG: /mgr } ) if $ENV{TEST_VERBOSE};

	my $loop = $self->loop;
	my $sess = $self->client;
	my $sim = $self->simulator;

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

	is $self->client_transitions->[-1]->transition, EV_TIMED_OUT, 'timed out';
	is $self->client_transitions->[-1]->to, STATE_N_IDLE, 'idle';
};

run_me;
done_testing;
