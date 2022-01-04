package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Control;
# ABSTRACT: Session control transitions

use Mu::Role;
use MooX::Should;

use Types::Standard qw(CodeRef InstanceOf);

use Future::AsyncAwait;
use Future::Buffer;
use boolean;

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENQ
	EOT
	ACK NAK

	CR LF
);
use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS_DEBUG);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :timer);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame;
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::TimerFactory';

use Data::Hexdumper ();

use constant END_OF_FRAME_RE => do {
	my $re = join "|",
		map {
			my @ends = @$_;
			Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame->_chars_to_hex_re( @ends )
		} (
			[ ENQ ],
			[ EOT ],
			[ ACK ],
			[ NAK ],
			[ CR, LF ], );
	qr/$re/;
};

requires '_recv_data';
requires '_send_data';

#### Read data

lazy _buffer => sub {
	my ($self) = @_;
	my $buffer = Future::Buffer->new(
		fill => async sub {
			my $data = await $self->_recv_data( 4096 );
		}
	);
};

has _read_control_future => (
	is => 'rw',
	predicate => 1, # _has_read_control_future
	clearer => 1,   # _clear_read_control_future
);

sub _read_control {
	my ($self) = @_;
	# Using without_cancel here because this future is shared amongst
	# multiple events.
	if( $self->_has_read_control_future ) {
		return $self->_read_control_future->without_cancel
	}

	my $f = $self->_buffer->read_until( END_OF_FRAME_RE )
		->set_label('read control');
	if( LIS_DEBUG && $self->_logger->is_trace) {
		$f = $f->then(sub {
			my ($result) = @_;
			$self->_logger->trace( $self->_logger_name_prefix . "Read control:\n"
				. Data::Hexdumper::hexdump( data => $result, suppress_warnings => true ) );
			Future->done( $result )
		});
	}
	$self->_read_control_future( $f );

	$f->without_cancel;
}

after _reset_after_step => sub {
	my ($self) = @_;
	if( $self->_has_read_control_future
		&& $self->_read_control_future->is_done ) {

		$self->_clear_read_control_future;
	}
};

#### Timer

has _timer_factory => (
	is => 'rw',
	isa => InstanceOf[TimerFactory],
	default => sub { TimerFactory->new; },
);

has _timer => (
	is => 'rw',
	lazy => 1,
	default => sub {
		my ($self) = @_;
		$self->_timer_factory->at_initial;
	},
);

async sub time_out {
	my ($self) = @_;
	await $self->_timer->timed_out;
};

#### Busy status

has busy_cb => (
	is => 'ro',
	should => CodeRef,
	default => sub {
		return sub { Future->done(false) }
	},
);

has _busy_future => (
	is => 'rw',
	predicate => 1, # _has_busy_future
	clearer => 1,   # _clear_busy_future
);

sub _status_busy {
	my ($self) = @_;
	if( $self->_has_busy_future ) {
		return $self->_busy_future->without_cancel;
	}

	my $f = $self->busy_cb->()
		->set_label('busy_cb');
	$self->_busy_future( $f );

	$f->without_cancel;
}

after _reset_after_step => sub {
	my ($self) = @_;
	if( $self->_has_busy_future ) {
		$self->_busy_future->cancel;
		$self->_clear_busy_future;
	}
};

#### Interrupt

has interrupt_cb => (
	is => 'ro',
	should => CodeRef,
	default => sub {
		return sub { Future->done(false) }
	},
);

has _interrupt_future => (
	is => 'rw',
	predicate => 1, # _has_interrupt_future
	clearer => 1,   # _clear_interrupt_future
);

sub _status_interrupt {
	my ($self) = @_;
	if( $self->_has_interrupt_future ) {
		return $self->_interrupt_future->without_cancel;
	}

	my $f = $self->interrupt_cb->()
		->set_label('interrupt_cb');
	$self->_interrupt_future( $f );

	$f->without_cancel;
}

### ACTIONS

async sub do_send_enq {
	await $_[0]->_send_data( ENQ );
}

async sub do_send_eot {
	await $_[0]->_send_data( EOT );
}

async sub do_send_ack {
	await $_[0]->_send_data( ACK );
}

async sub do_send_nak {
	await $_[0]->_send_data( NAK );
}

async sub do_reset_receiver_timer {
	my ($self) = @_;
	$self->_timer( $self->_timer_factory->at_receiver );
}

async sub do_reset_sender_timer {
	my ($self) = @_;
	$self->_timer( $self->_timer_factory->at_sender );
}

async sub do_reset_contention_busy_timer {
	my ($self) = @_;
	if( await $self->event_on_receive_enq ) {
		$self->_timer( $self->_timer_factory
			->at_contention_for_system($self->session_system)
		);
	} else {
		$self->_timer( $self->_timer_factory->at_busy );
	}
}

async sub do_request_interrupt {
	# TODO
}

### EVENTS

async sub event_on_receive_eot {
	my ($self) = @_;
	die unless ( (await $self->_read_control) eq EOT );
}

async sub event_on_receive_eot_or_time_out {
	my ($self) = @_;
	die unless
		(await $self->_read_control) eq EOT
		||
		( await $self->time_out )
}

async sub event_on_receive_enq_or_nak {
	my ($self) = @_;
	my $read = await $self->_read_control;
	die unless $read eq ENQ || $read eq NAK;
}

async sub event_on_receive_enq {
	my ($self) = @_;
	die unless (await $self->_read_control) eq ENQ;
}

async sub event_on_receive_ack {
	my ($self) = @_;
	die unless (await $self->_read_control) eq ACK;
}

async sub event_on_receive_nak_or_fail {
	my ($self) = @_;
	my $read = await $self->_read_control;

	# Got a NAK
	my $is_nak = $read eq NAK;

	# Got any character other than ACK or EOT
	my $is_fail = !( $read eq ACK || $read eq EOT );

	die unless $is_nak || $is_fail;
}

async sub event_on_establishment_timers_running {
	my ($self) = @_;
	die; # DEBUG
	#die unless ! $self->_timer->future->is_ready;
}

async sub event_on_establishment_timers_timed_out {
	my ($self) = @_;
	return true; # DEBUG
	#my $timed_out = await $self->time_out;
	#die unless $timed_out;
}

async sub event_on_busy {
	my ($self) = @_;
	my $is_busy = await $self->_status_busy;
	die unless $is_busy;
}

async sub event_on_not_busy {
	my ($self) = @_;
	my $is_busy = await $self->_status_busy;
	die unless ! $is_busy;
}

async sub event_on_interrupt_ignore {
	# TODO
	true;
}

async sub event_on_interrupt_accept_or_time_out {
	# TODO
	die;
}

async sub event_on_timed_out {
	my ($self) = @_;
	#die; # DEBUG
	die unless await $self->_timer->timed_out;
}

1;
