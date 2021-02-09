package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Context;
# ABSTRACT: Session context

use Mu::Role;
use MooX::Enumeration;

use Types::Standard qw(Enum);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_device :enum_state);

has connection => (
	is => 'ro',
	required => 1,
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

1;
