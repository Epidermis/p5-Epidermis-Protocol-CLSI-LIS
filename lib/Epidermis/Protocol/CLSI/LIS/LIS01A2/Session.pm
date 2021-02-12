package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;
use MooX::HandlesVia;
use MooX::Should;

use Types::Standard qw(ArrayRef InstanceOf HashRef Dict);

use Future::AsyncAwait;
use Future::IO;

our $MessageType = InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Message'];

has _message_queue => (
	is => 'ro',
	default => sub { [] },
	should => ArrayRef[
		Dict[
			message => $MessageType,
			future  => InstanceOf['Future'],
		]
	],
	handles_via => 'Array',
	handles => {
		_message_queue_is_empty => 'is_empty',
		_message_queue_size => 'count',
		_message_queue_enqueue => 'push',
		_message_queue_dequeue => 'shift',
		_message_queue_peek => 'shift',
	},
);

has _future_data_to_send => (
	is => 'ro',
	should => InstanceOf['Future'],
	default => sub { Future->new },
);

sub send_message {
	my ($self, $message) = @_;
	$MessageType->assert_valid( $message );
	my $empty = $self->_message_queue_is_empty;
	my $f = Future->new;
	$self->_message_queue_enqueue( { message => $message, future => $f } );

	if( $empty ) {
		$self->_future_data_to_send->done
	}

	$f;
}

sub _send_frame {
	...
}

async sub _recv_data {
	my ($self) = @_;
	Future::IO->sysread( $self->connection->handle, 4096 );
}

async sub _send_data {
	my ($self, $data) = @_;
	Future::IO->syswrite( $self->connection->handle , $data );
}

async sub step {
	my ($self) = @_;
	my $events = $self->state_machine->events_for_state( $self->session_state );
	my @event_cb = @{ $self->_event_dispatch_table }{ @$events };
	my $event = await Future->wait_any( @event_cb );
}


async sub event_on_good_frame {
}
async sub event_on_get_frame {
}
async sub event_on_busy {
}
async sub event_on_not_busy {
}
async sub event_on_has_data_to_send {
}
async sub event_on_any {
}
async sub event_on_interrupt_ignore {
}
async sub event_on_interrupt_accept_or_time_out {
}
async sub event_on_timed_out {
}
async sub event_on_no_can_retry {
}
async sub event_on_not_has_data_to_send {
}
async sub event_on_can_retry {
}
async sub event_on_bad_frame {
}
async sub event_on_establishment_timers_running {
}
async sub event_on_establishment_timers_timed_out {
}


with qw(
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Context
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable

	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Device
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Control
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::FrameNumber
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Retry

	MooX::Role::Logger
);

1;
