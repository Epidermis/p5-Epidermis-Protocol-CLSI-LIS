package # hide from PAUSE
	Test::SessionSim;
# ABSTRACT: Test class for setting up simulator

use Test2::Roo::Role;
use Mu::Role;
use namespace::autoclean;

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
};

before setup => sub {
	my ($self) = @_;
	my $test_conn = $self->connection;
	$test_conn->init;
};

1;
