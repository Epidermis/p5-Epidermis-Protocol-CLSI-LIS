package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::DataTransfer;
# ABSTRACT: Role for session data transfer

use Mu::Role;
use MooX::HandlesVia;
use MooX::Should;

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
		$self->_logger->trace( $self->_logger_name_prefix . "Received data <@{[ $self->session_system ]}>:\n"
			. Data::Hexdumper::hexdump( data => $data, suppress_warnings => true ) )
	} if LIS_DEBUG && $self->_logger->is_trace;
	return $data;
}

async sub _send_data {
	my ($self, $data) = @_;
	do {
		$self->_logger->trace( $self->_logger_name_prefix . "Sending data <@{[ $self->session_system ]}>:\n"
			. Data::Hexdumper::hexdump( data => $data, suppress_warnings => true ) )
	} if LIS_DEBUG && $self->_logger->is_trace;
	await Future::IO->syswrite_exactly( $self->connection->handle , $data );
}

1;
