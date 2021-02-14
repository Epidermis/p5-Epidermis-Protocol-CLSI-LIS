package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;
use MooX::HandlesVia;
use MooX::Should;

use Data::Dumper;

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
	do {
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		$self->_logger->debug( "State @{[ $self->session_state ]}: Events " . Dumper($events) )
	} if $self->_logger->is_debug;
	my @event_cb = @{ $self->_event_dispatch_table }{ @$events };
	my $event = await Future->wait_any( map { $_->() } @event_cb );
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
