package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Context;
# ABSTRACT: Context for a session

use Moo;
use MooX::Enumeration;

use Types::Standard qw(Enum);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants qw( :enum_system :enum_device :enum_state );

has session_system => (
	is => 'ro',
	isa => Enum[ @ENUM_SYSTEM ],
	default => sub { SYSTEM_COMPUTER },
);

has device_type => (
	is => 'rw',
	isa => Enum[ @ENUM_DEVICE ],
	init_arg => undef,
	default => sub { DEVICE_NONE },
);

has session_state => (
	is => 'rw',
	isa => Enum[ @ENUM_STATE ],
	init_arg => undef,
	default => sub { STATE_N_IDLE },
);

1;
