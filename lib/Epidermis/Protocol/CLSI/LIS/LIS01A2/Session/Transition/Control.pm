package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Control;
# ABSTRACT: Session control transitions

use Mu::Role;
use Future::AsyncAwait;
use Future::Buffer;
use Future::IO;

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENQ
	EOT
	ACK NAK
);

requires '_send_data';

lazy _buffer => sub {
	my $buffer = Future::Buffer->new(
		fill => async sub {
				await Future::IO->sysread(\*STDIN, 4096);
		}
	);
};

has _timer => (
	is => 'ro',
);

### ACTIONS

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

async sub event_on_establishment_timers_running {
	...
}

async sub event_on_establishment_timers_timed_out {
	...
}

async sub event_on_busy {
	...
}

async sub event_on_not_busy {
	...
}

async sub event_on_interrupt_ignore {
	...
}

async sub event_on_interrupt_accept_or_time_out {
	...
}

async sub event_on_timed_out {
	...
}

1;
