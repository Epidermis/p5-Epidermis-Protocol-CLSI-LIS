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

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state :enum_event);

use feature qw(state);
use IO::Async::Timer::Periodic;
use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

lazy loop => sub {
	my $loop = IO::Async::Loop->new;
};

lazy connection => sub {
	my $test_conn = Connection->build_test_connection;
};

lazy local => sub {
	my ($self) = @_;
	Simulator->new(
		session => Session->new(
			connection => $self->connection->connection0,
			session_system => SYSTEM_COMPUTER,
			name => 'cli',
		),
		commands => $self->local_steps,
	);
};

lazy remote => sub {
	my ($self) = @_;
	Simulator->new(
		session => Session->new(
			connection => $self->connection->connection1,
			session_system => SYSTEM_INSTRUMENT,
			name => 'sim',
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
		#category => qr/^main$|^Epidermis::Protocol::CLSI::LIS::LIS01A2::Client/
		},
		'Screen', min_level => 'trace', formatter => sub { $_[1] =~ s/^/  # LOG: /mgr } ) if $ENV{TEST_VERBOSE};

	my $loop = $self->loop;

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
			$self->local->process_commands,
			$self->remote->process_commands,
		);
		$loop->stop;
	});

	$loop->run;

	is $self->local->transitions->[-1]->transition, EV_TIMED_OUT, 'timed out';
	is $self->local->transitions->[-1]->to, STATE_N_IDLE, 'idle';
};

1;
