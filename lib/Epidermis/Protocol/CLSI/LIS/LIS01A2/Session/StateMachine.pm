package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine;
# ABSTRACT: A state machine for the session

use Moo;
use MooX::Enumeration;

use boolean;
use Const::Fast;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants qw(:enum_device :enum_state);

	# - Await for data to send => STATE_S_ESTABLISH_SEND_DATA
	# - Receive <ENQ>          => STATE_R_AWAKE

no strict "subs"; ## no critic: 'RequireUseStrict'

const our $STATE_MAP => {
	STATE_N_IDLE ,=> {
		STATE_S_ESTABLISH_SEND_DATA ,=> {
			on => { code => \&_has_data_to_send, },
			do => { code => \&_set_device_to_sender, },
		},
		STATE_R_AWAKE ,=> {
			on => { code => \&_on_receive_enq, },
			do => { code => \&_set_device_to_receiver, }
		},
	},

	STATE_R_AWAKE ,=> {
		STATE_N_IDLE ,=> {
			on => { code => \&_on_is_busy, },
		},
		STATE_R_WAITING ,=> { },
	},
	STATE_R_WAITING ,=> {
		STATE_R_FRAME_RECEIVED ,=> {},
		STATE_N_IDLE ,=> {},
	},
	STATE_R_FRAME_RECEIVED ,=> {
	},
	STATE_R_SEND_DATA ,=> {
	},

	STATE_S_ESTABLISH_SEND_DATA ,=> {
	},
	STATE_S_ESTABLISH_CONTENTION_BUSY ,=> {
	},
	STATE_S_ESTABLISH_WAITING ,=> {
	},

	STATE_S_TRANSFER_SETUP_NEXT_FRAME ,=> {
	},
	STATE_S_TRANSFER_FRAME_READY ,=> {
	},
	STATE_S_TRANSFER_WAITING ,=> {
	},
	STATE_S_TRANSFER_SETUP_OLD_FRAME ,=> {
	},
	STATE_S_TRANSFER_INTERRUPT ,=> {
	},
};

sub reset {
	my ($self, $context) = @_;
	$self->session_state( STATE_N_IDLE );
}

sub _set_device_to_sender {
	my ($self, $context) = @_;
	$context->device_type( DEVICE_SENDER );
}

sub _set_device_to_receiver {
	my ($self, $context) = @_;
	$context->device_type( DEVICE_RECEIVER );
}

sub _has_data_to_send {
	my ($self, $context) = @_;
	# TODO
	$context->has_data;
}

sub _on_receive_enq {
	...
}

sub _on_is_busy {
	...
}

sub _on_not_busy {
	...
}

1;
