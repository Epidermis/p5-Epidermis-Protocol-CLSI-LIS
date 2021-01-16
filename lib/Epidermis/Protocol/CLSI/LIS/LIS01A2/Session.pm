package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Moo;
use MooX::Enumeration;

use Types::Standard qw(Enum Str);

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENQ
	EOT
	ACK NAK
);

has connection => (
	is => 'ro',
	required => 1,
);

sub start {
	my ($self) = @_;
	$self->session_state( STATE_N_IDLE );
}

sub send_message {
	kk
}

sub _send_frame {
	...
}

1;
