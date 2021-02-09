package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine;
# ABSTRACT: Session state machine role

use Mu::Role;
use MooX::Enumeration;

use Types::Standard qw(Enum);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine';

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

has state_machine => (
	is => 'ro',
	default => sub { StateMachine->new; },
);

has session_state => (
	is => 'rw',
	isa => Enum[ @ENUM_STATE ],
	init_arg => undef,
	default => sub { STATE__START_STATE },
);

1;
