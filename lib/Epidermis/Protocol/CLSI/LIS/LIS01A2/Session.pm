package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;
use MooX::HandlesVia;
use MooX::Should;
use MooX::Role::Logger (); # declare dependency (role)

use overload
	'""' => \&TO_STRING;

use Data::Hexdumper ();

use Types::Standard qw(ArrayRef InstanceOf);
use boolean;

use Future::AsyncAwait;
use Future::IO;

use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS_DEBUG);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue;

has _message_queue => (
	is => 'ro',
	default => sub { [] },
	should => ArrayRef[
		$Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue::MessageQueueItem->TYPE_TINY
	],
	handles_via => 'Array',
	handles => {
		_message_queue_is_empty => 'is_empty',
		_message_queue_size => 'count',
		_message_queue_enqueue => 'push',
		_message_queue_dequeue => 'shift',
		_message_queue_peek => [ 'get', 0 ],
	},
);

has _data_to_send_future => (
	is => 'rw',
	should => InstanceOf['Future'],
	default => sub { Future->new },
);

has _message_queue_empty_future => (
	is => 'rw',
	should => InstanceOf['Future'],
	default => sub { Future->done(true) },
);

sub send_message {
	my ($self, $message) = @_;
	my $empty = $self->_message_queue_is_empty;
	my $mq_item = $Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue::MessageQueueItem->new(
		message => $message,
	);
	$self->_message_queue_enqueue( $mq_item );

	if( $empty ) {
		$self->_data_to_send_future->done(true);
	}

	$mq_item->future;
}

async sub _recv_data {
	my ($self, $len) = @_;
	my $data = await Future::IO->sysread( $self->connection->handle, $len );
	do {
		$self->_logger->trace( "Received data <@{[ $self->session_system ]}>:\n"
			. Data::Hexdumper::hexdump( data => $data, suppress_warnings => true ) )
	} if LIS_DEBUG && $self->_logger->is_trace;
	return $data;
}

async sub _send_data {
	my ($self, $data) = @_;
	do {
		$self->_logger->trace( "Sending data <@{[ $self->session_system ]}>:\n"
			. Data::Hexdumper::hexdump( data => $data, suppress_warnings => true ) )
	} if LIS_DEBUG && $self->_logger->is_trace;
	await Future::IO->syswrite_exactly( $self->connection->handle , $data );
}


sub TO_STRING {
	my ($self) = @_;
	"Session: [ @{[ $self->STATE_TO_STRING ]}, @{[ $self->CONTEXT_TO_STRING ]} ]"
}

with qw(
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Context
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable

	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Device
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Control
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::FrameNumber
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Retry
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Data
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Any

	MooX::Role::Logger
);

1;
