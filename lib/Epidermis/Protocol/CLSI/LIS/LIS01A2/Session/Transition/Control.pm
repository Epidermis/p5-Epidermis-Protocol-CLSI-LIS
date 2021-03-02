package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Control;
# ABSTRACT: Session control transitions

use Mu::Role;
use MooX::Should;

use Types::Standard qw(CodeRef);

use Future::AsyncAwait;
use Future::Buffer;
use Future::IO;
use boolean;

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENQ
	EOT
	ACK NAK

	CR LF
);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame;

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
			my $data = await $self->_recv_data( 1 );
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
	if( $self->_has_read_control_future ) {
		return $self->_read_control_future
	}

	my $f = $self->_buffer->read_until( END_OF_FRAME_RE )
		->set_label('read control');
	$self->_read_control_future( $f );

	$f;
}

after _reset_after_step => sub {
	my ($self) = @_;
	if( $self->_has_read_control_future ) {
		$self->_read_control_future->cancel;
		$self->_clear_read_control_future;
	}
};

#### Timer

has _timer => (
	is => 'rw',
	default => sub {
		+{
			type => 'initial',
			future => Future->done,
		}
	},
);

async sub time_out {
	my ($self) = @_;
	my $future = $self->_timer->{future};

	my $timed_out;
	await $future->on_cancel(sub {
		$timed_out = 0;
	})->on_done(sub {
		$timed_out = 1;
	});

	return $timed_out;
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
		return $self->_busy_future;
	}

	my $f = $self->busy_cb->()
		->set_label('busy_cb');
	$self->_busy_future( $f );

	$f;
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
		return $self->_interrupt_future;
	}

	my $f = $self->interrupt_cb->()
		->set_label('interrupt_cb');
	$self->_interrupt_future( $f );

	$f;
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
	$self->_timer( {
		type => 'receiver',
		future => Future::IO->sleep(30)->set_label('receiver timer')
	} );
}

async sub do_reset_sender_timer {
	my ($self) = @_;
	$self->_timer( {
		type => 'sender',
		future => Future::IO->sleep(15)->set_label('sender timer')
	} );
}

async sub do_reset_contention_busy_timer {
	my ($self) = @_;
	if( await $self->event_on_receive_enq ) {
		$self->_timer( {
			type => 'contention',
			future => Future::IO->sleep(
					$self->session_system eq SYSTEM_INSTRUMENT
					? 1
					: 20
				)->set_label('contention timer')
		} );
	} else {
		$self->_timer( {
			type => 'busy',
			future => Future::IO->sleep(10)
				->set_label('busy timer')
		} );
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
	die unless ! $self->_timer->{future}->is_ready;
}

async sub event_on_establishment_timers_timed_out {
	my ($self) = @_;
	die unless $self->_timer->{future}->is_ready;
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
	await $self->_timer->{future};
}

1;
