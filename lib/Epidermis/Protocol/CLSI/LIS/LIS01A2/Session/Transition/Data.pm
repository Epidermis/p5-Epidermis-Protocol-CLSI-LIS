package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Data;
# ABSTRACT: Data transitions

use Moo::Role;
use Future::AsyncAwait;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue;
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame;

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	STX
);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_device);

use boolean;

requires '_data_to_send_future';

requires '_message_queue';
requires '_frame_number';

requires '_read_control';

has _current_sendable_message => (
	is => 'rw',
	predicate => 1,
	clearer => 1,
);

after _reset_after_step => sub {
	my ($self) = @_;
	$self->_update_data_to_send_future;
};

sub _update_data_to_send_future {
	my ($self) = @_;
	# Treat these two futures as producer-consumer semaphores.
	my $is_empty = $self->_message_queue_is_empty;
	$self->_data_to_send_future( Future->new ) if $self->_data_to_send_future->is_ready;
	$self->_message_queue_empty_future( Future->done( $is_empty ) );
}

### ACTIONS

async sub do_send_frame {
	my ($self) = @_;
	return unless $self->_has_current_sendable_message; # DEBUG
	await $self->_send_data(
		$self->_current_sendable_message->get_current_frame->frame_data
	);
}

async sub do_setup_next_frame {
	my ($self) = @_;

	my $create_new_sendable_message = 0;
	if( ! $self->_has_current_sendable_message ) {
		$create_new_sendable_message = 1;
	} elsif( ! $self->_current_sendable_message->has_next_frame ) {
		$create_new_sendable_message = 1;
		$self->_message_queue_dequeue->future->done;
	}

	if( $create_new_sendable_message ) {
		if( $self->_message_queue_size ) {
			$self->_logger->trace( 'Creating new sendable message' );
			$self->_current_sendable_message(
				$Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue::SendableMessage->new(
					message_item => $self->_message_queue_peek,
					initial_fn => $self->_frame_number,
				)
			);
		} else {
			$self->_logger->trace( 'Message queue empty' );
			$self->_clear_current_sendable_message;
		}
	} else {
		$self->_current_sendable_message->next_frame;
	}
}

async sub do_setup_old_frame {
	true;
}

### EVENTS

async sub event_on_good_frame {
	# TODO
	true; # DEBUG
}

async sub event_on_get_frame {
	# TODO
	my ($self) = @_;
	my $frame_data = await $self->_read_control;

	# Check this early to return from event early.
	die 'Invalid frame data: no STX' unless $frame_data =~ /\Q@{[ STX ]}\E/;

	my $frame = eval {
		Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame->parse_frame_data( $frame_data );
	};
	use Data::Dumper; $self->_logger->trace( Dumper($frame) ); # DEBUG

	$frame;
}

async sub event_on_has_data_to_send {
	my ($self) = @_;
	die if $self->device_type eq DEVICE_RECEIVER; # debug
	die unless await $self->_data_to_send_future;
}

async sub event_on_not_has_data_to_send {
	my ($self) = @_;
	return true if $self->device_type eq DEVICE_RECEIVER; # debug
	die if await $self->_data_to_send_future;
}

async sub event_on_transfer_done {
	my ($self) = @_;
	die unless await $self->_message_queue_empty_future;
}

async sub event_on_not_transfer_done {
	my ($self) = @_;
	die if await $self->_message_queue_empty_future;
}

async sub event_on_bad_frame {
	# TODO
	...
}

1;
