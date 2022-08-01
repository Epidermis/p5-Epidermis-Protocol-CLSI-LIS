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
use aliased 'Epidermis::Lab::Role::ConnectionHandles';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Simulator';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::TimerFactory';

use aliased 'Test::TimerFactory::Factor';

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state :enum_event);

use feature qw(state);
use IO::Async::Timer::Periodic;
use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

use Log::Any qw($log);

lazy loop => sub {
	my $loop = IO::Async::Loop->new;
};

lazy connection => sub {
	my $test_conn = Connection->build_test_connection;
};

lazy timer_factory => sub {
	Moo::Role->create_class_with_roles(
		TimerFactory,
		Factor
	)->new(
		factor => 1/8,
	);
};

lazy session_class => sub {
	Moo::Role->create_class_with_roles(
		Session,
		ConnectionHandles
	);
};

lazy local => sub {
	my ($self) = @_;
	Simulator->new(
		session => $self->session_class->new(
			connection => $self->connection->connection0,
			session_system => SYSTEM_COMPUTER,
			name => 'cli',
			_timer_factory => $self->timer_factory,
		),
		commands => $self->local_steps,
	);
};

lazy remote => sub {
	my ($self) = @_;
	Simulator->new(
		session => $self->session_class->new(
			connection => $self->connection->connection1,
			session_system => SYSTEM_INSTRUMENT,
			name => 'sim',
			_timer_factory => $self->timer_factory,
		),
		commands => $self->remote_steps,
	);
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

requires 'local_steps';
requires 'remote_steps';

test "Simulate" => sub {
	my $self = shift;
	Log::Any::Adapter->set( {
		lexically => \my $lex,
		category => qr/
			^main$
			| ^Test::SessionSim$
			| ^Epidermis::Protocol::CLSI::LIS::LIS01A2::Simulator
			| ^Epidermis::Protocol::CLSI::LIS::LIS01A2::Session
		/x
	}, 'Screen', min_level => 'trace',
		formatter => sub {
		$_[1] =~ s/^/  # LOG: /mgr
	} ) if $ENV{TEST_VERBOSE};

	my $loop = $self->loop;

	my $timer = IO::Async::Timer::Periodic->new(
		interval => 1,
		on_tick => sub {
			state $tick = 0;
			$log->tracef("Timer: %d", ++$tick)
				 if $log->is_trace;
		},
	);
	$loop->later(sub {
		$timer->start;
		$loop->add( $timer );
	});
	$loop->later(sub {
		$loop->await_all(
			$self->local->process_commands,
			$self->remote->process_commands,
		);
		$loop->stop;
	});

	$loop->run;
};

1;
