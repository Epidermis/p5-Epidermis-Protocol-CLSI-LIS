package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Control;
# ABSTRACT: Control character actions

use Moo::Role;
use Future::AsyncAwait;

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENQ
	EOT
	ACK NAK
);

requires '_send_data';

async sub do_send_enq {
	$_[0]->_send_data( ENQ );
}

async sub do_send_eot {
	$_[0]->_send_data( EOT );
}

async sub do_send_ack {
	$_[0]->_send_data( ACK );
}

async sub do_send_nak {
	$_[0]->_send_data( NAK );
}

### EVENTS

async sub event_on_receive_eot {
	my ($self) = @_;
	die unless $self->_cached_read eq EOT;
}

async sub event_on_receive_eot_or_time_out {
	my ($self) = @_;
	...;
}

async sub event_on_receive_enq_or_nak {
	my ($self) = @_;
	...;
}

async sub event_on_receive_enq {
	my ($self) = @_;
	...;
}

async sub event_on_receive_ack {
	my ($self) = @_;
	...;
}

async sub event_on_receive_nak_or_fail {
	my ($self) = @_;
	...;
}

1;
