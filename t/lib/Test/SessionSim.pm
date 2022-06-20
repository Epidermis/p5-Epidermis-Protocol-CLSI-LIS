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
use Future::Utils qw(repeat try_repeat);
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
		session => Client->new(
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

requires 'client_steps';
requires 'simulator_steps';

use Const::Exporter default => [
	CMD_STEP_UNTIL_IDLE => 'step-until-idle',
	CMD_STEP_UNTIL     => 'step',
	CMD_SLEEP          => 'sleep',
	CMD_SEND_MSG       => 'send-message',
];

sub driver {
	my ($self, $session, $events) = @_;
	my ($last_idx, $last_event, @last_data);
	my $sim_process_events_f = try_repeat {
		my $idx = shift;
		my ($state, $event_name, @data) = @{ $events->[$idx] };

		if( $session->session_state eq $state ) {
			$last_event = $event_name;
			@last_data  = @data;
		}

		if( $last_event eq CMD_STEP_UNTIL_IDLE ) {
			print "[Process @{[ $session->name ]} until idle", "]\n";
			$session->_process_until_state( STATE_N_IDLE );
		} elsif( $last_event eq CMD_STEP_UNTIL ) {
			print "[Process @{[ $session->name ]} until ", $events->[$idx + 1][0], "]\n";
			$session->_process_until_state( $events->[$idx + 1][0]);
		} elsif( $last_event eq CMD_SLEEP ) {
			print "[sleep for ", $last_data[0], "]\n";
			Future::IO->sleep($last_data[0]);
		} elsif( $last_event eq CMD_SEND_MSG ) {
			print "[send message ", $last_data[0], "]\n";
			$session->send_message( $last_data[0] );
			Future->done;
		}
	} foreach => [ 0..@$events-1 ];
}

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
			$self->driver( $sess, $self->client_steps ),
			$self->driver( $self->simulator->session, $self->simulator_steps ),
		);
		$loop->stop;
	});

	$loop->run;

	is $self->client_transitions->[-1]->transition, EV_TIMED_OUT, 'timed out';
	is $self->client_transitions->[-1]->to, STATE_N_IDLE, 'idle';
};

1;
