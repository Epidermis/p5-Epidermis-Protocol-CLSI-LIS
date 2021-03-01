package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Data;
# ABSTRACT: Data transitions

use Moo::Role;
use Future::AsyncAwait;

after _reset_after_step => sub {
	my ($self) = @_;
	#$self->_update_data_to_send_future;
};

sub _update_data_to_send_future {
	my ($self) = @_;
	if( $self->_data_to_send_future ) {
		$self->_data_to_send_future->cancel;
	}
	if( $self->_message_queue_size ) {
		$self->_data_to_send_future( Future->done )
	} else {
		$self->_data_to_send_future( Future->fail( data => 'no data' ) )
	}
}

### ACTIONS

async sub do_send_frame {
	# TODO
	...
}

async sub do_setup_next_frame {
	# TODO
	...
}

async sub do_setup_old_frame {
	# TODO
	die;
}

### EVENTS

async sub event_on_good_frame {
	# TODO
	...
}

async sub event_on_get_frame {
	# TODO
	...
}

async sub event_on_has_data_to_send {
	my ($self) = @_;
	die unless $self->_data_to_send_future->is_done;
}

async sub event_on_not_has_data_to_send {
	my ($self) = @_;
	die if $self->_data_to_send_future->is_done;
}

async sub event_on_bad_frame {
	# TODO
}

1;
