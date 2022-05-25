package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Context;
# ABSTRACT: Session context

use Mu::Role;
use namespace::autoclean;
use MooX::Enumeration;

use Types::Standard qw(Enum);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_device);

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

has name => (
	is => 'ro',
	default => sub { '' },
);

sub _logger_name_prefix {
	my ($self) = @_;
	if( $self->name ) {
		return $self->name . "| ";
	}
	return '';
}

sub CONTEXT_TO_STRING {
	my ($self) = @_;
	"[ Context: [ System: <@{[ $self->session_system ]}>, Device type: <@{[ $self->device_type ]}> ] ]";
}

1;
