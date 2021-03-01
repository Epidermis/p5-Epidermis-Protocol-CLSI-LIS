package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;
use MooX::HandlesVia;
use MooX::Should;

use overload
	'""' => \&TO_STRING;

use Data::Dumper;

use Types::Standard qw(ArrayRef InstanceOf HashRef Dict);

use Future::AsyncAwait;
use Future::IO;

use constant DEBUG => $ENV{EPIDERMIS_CLSI_DEBUG} // 0;

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
	my ($self, $len) = @_;
	my $data = await Future::IO->sysread_exactly( $self->connection->handle, $len );
	do {
		local $Data::Dumper::Useqq = 1;
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		$self->_logger->trace( "Received data: " . Dumper($data) )
	} if DEBUG && $self->_logger->is_trace;
	return $data;
}

async sub _send_data {
	my ($self, $data) = @_;
	do {
		local $Data::Dumper::Useqq = 1;
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		$self->_logger->trace( "Sending data: " . Dumper($data) )
	} if DEBUG && $self->_logger->is_trace;
	await Future::IO->syswrite_exactly( $self->connection->handle , $data );
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
