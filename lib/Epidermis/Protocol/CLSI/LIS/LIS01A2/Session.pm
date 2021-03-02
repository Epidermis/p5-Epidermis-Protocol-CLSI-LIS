package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;
use MooX::HandlesVia;
use MooX::Should;

use overload
	'""' => \&TO_STRING;

use Data::Dumper;
use Data::Hexdumper ();

use Types::Standard qw(ArrayRef InstanceOf);
use boolean;

use Future::AsyncAwait;
use Future::IO;

use constant DEBUG => $ENV{EPIDERMIS_CLSI_DEBUG} // 0;

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

sub send_message {
	my ($self, $message) = @_;
	my $empty = $self->_message_queue_is_empty;
	my $mq_item = $Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue::MessageQueueItem->new(
		message => $message,
	);
	$self->_message_queue_enqueue( $mq_item );

	if( $empty ) {
		$self->_data_to_send_future->done
	}

	$mq_item->future;
}

sub _send_frame {
	...
}

async sub _recv_data {
	my ($self, $len) = @_;
	my $data = await Future::IO->sysread_exactly( $self->connection->handle, $len );
	do {
		$self->_logger->trace( "Received data <@{[ $self->session_system ]}>:\n"
			. Data::Hexdumper::hexdump( data => $data, suppress_warnings => true ) )
	} if DEBUG && $self->_logger->is_trace;
	return $data;
}

async sub _send_data {
	my ($self, $data) = @_;
	do {
		$self->_logger->trace( "Sending data <@{[ $self->session_system ]}>:\n"
			. Data::Hexdumper::hexdump( data => $data, suppress_warnings => true ) )
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
	my @events_cb = @{ $self->_event_dispatch_table }{ @$events };

	my $transition_event = await Future->needs_any( map {
		my $idx = $_;
		my $f = $events_cb[$idx]->($self)
			->transform( done => sub { $events->[$idx] } )
			->set_label( $events->[$idx] )
	} 0..@events_cb-1 )->set_label("$self : events");

	my $from = $self->session_state;
	my $transition_data = $self->state_machine->process_event(
		$self,
		$transition_event
	);

	do {
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		$self->_logger->debug( "Transition: [ @{[ $from ]} ] -- @{[ $transition_event ]} --> [ @{[ $transition_data->{to} ]} ]" )
	} if $self->_logger->is_debug;

	$self->session_state( $transition_data->{to} );

	my @actions = @{ $transition_data->{action} };
	my $actions_done = Future->needs_all( map {
		my $action = $_;
		my $f = $self->_action_dispatch_table->{$action}->($self)
			->set_label($action)
	} @actions)->set_label( 'actions' );

	await $actions_done->followed_by( sub { $self->_reset_after_step } );
}

sub _reset_after_step { }

sub TO_STRING {
	my ($self) = @_;
	"Session: [ @{[ $self->STATE_TO_STRING ]}, @{[ $self->CONTEXT_TO_STRING ]} ]"
}

async sub _counter {
	my ($self) = @_;
	my $counter = 0;
	while( 1 ) {
		await Future::IO->sleep(1);
		await Future::IO->syswrite(
			\*STDERR,
			sprintf( "System: [%s] counter: %d\n", $self->session_system,  ++$counter)
		);
	}
	return 0;
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
