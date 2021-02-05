package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;
use MooX::Enumeration;

use Types::Standard qw(Enum Str);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine';

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_device :enum_state);

has connection => (
	is => 'ro',
	required => 1,
);

has state_machine => (
	is => 'ro',
	default => sub { StateMachine->new; },
);

has session_system => (
	is => 'ro',
	isa => Enum[ @ENUM_SYSTEM ],
	default => sub { SYSTEM_COMPUTER },
);

has device_type => (
	is => 'rw',
	isa => Enum[ @ENUM_DEVICE ],
	init_arg => undef,
	default => sub { DEVICE__START_DEVICE },
);

has session_state => (
	is => 'rw',
	isa => Enum[ @ENUM_STATE ],
	init_arg => undef,
	default => sub { STATE__START_STATE },
);

sub send_message {

}

sub _send_frame {
	...
}

with qw(
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable

	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Device
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Control
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::FrameNumber
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Retry
);

1;
