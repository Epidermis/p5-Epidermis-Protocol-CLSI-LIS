package # hide from PAUSE
	Test::SessionSim;
# ABSTRACT: Test class for setting up simulator

use Test2::Roo::Role;
use Mu::Role;

with qw( MooX::Role::Logger );

use lib 't/lib';
use Connection;

use IO::Async::Loop;
use Future::IO::Impl::IOAsync;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Simulator';

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Client';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEventEmitter' => 'Process::StepEventEmitter';

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state :enum_event);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';
use feature qw(state);
use IO::Async::Timer::Periodic;
use Future::Utils qw(repeat);
use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

lazy loop => sub {
	my $loop = IO::Async::Loop->new;
};

lazy connection => sub {
	my $test_conn = Connection->build_test_connection;
};

lazy client => sub {
	my ($self) = @_;
	my $client_class = Moo::Role->create_class_with_roles(Client, Process::StepEventEmitter);
	my $sess = $client_class->new(
		connection => $self->connection->connection0,
		session_system => SYSTEM_COMPUTER,
		name => 'cli',
	);

	my $step_count = 0;
	my $log = $self->_logger;
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
		push @{ $self->client_transitions }, $event->state_transition;
	});

	$sess;
};

ro client_transitions => (
	default => sub { [] },
);

lazy simulator => sub {
	my ($self) = @_;
	my $sim  = Simulator->new(
		session => Session->new(
			connection => $self->connection->connection1,
			session_system => SYSTEM_INSTRUMENT,
			name => 'sim',
		)
	);
	$sim;
};

sub BUILD {
	my ($self) = @_;
	my $test_conn = $self->connection;
	plan skip_all => "Could not create any test connection" unless $test_conn;
	note "Test connection: ", ref $test_conn;
}

before setup => sub {
	my ($self) = @_;
	my $test_conn = $self->connection;
	$test_conn->init;
};

requires 'simulator_events';

lazy simulator_process_events_future => sub {
	my ($self) = @_;

	my @events = @{ $self->simulator_events };
	my $sim    = $self->simulator;

	my $sim_process_events_f = repeat {
		my ($event_name, $data) = @{ shift @_ };
		$sim->process_event( $event_name, $data );
	} foreach => \@events;
};

test "Simulate" => sub {
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
			$self->simulator_process_events_future,
		);
		$loop->stop;
	});

	$loop->run;

	is $self->client_transitions->[-1]->transition, EV_TIMED_OUT, 'timed out';
	is $self->client_transitions->[-1]->to, STATE_N_IDLE, 'idle';
};

1;
