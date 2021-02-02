package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine;
# ABSTRACT: A state machine for the session

use Moo;
use MooX::Enumeration;
use Sub::Trigger::Lock;

use boolean;
use Const::Fast;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_device :enum_state :enum_event :enum_action);

has _state_map => ( is => 'ro', default => sub { +{} } );

sub _t {
	my ($self, %args) = @_;

	my $from = $args{from} or die "Transition requires 'from' argument";
	my $to = $args{to} or die "Transition requires 'to' argument";
	my $event = $args{event} or die "Transition requires 'event' argument";
	my $action = $args{action} or die "Transition requires 'action' argument";

	die "Already have transition from $from to $to"
		if exists $self->_state_map->{ $from }{ $to };

	$self->_state_map->{ $from }{ $to } = {
		event => $event,
		action => ref $action ? $action : [ $action ],
	};
}

sub BUILD {
	my ($self, $args) = @_;

	# Neutral Device
	$self->_t( from => STATE_N_IDLE, to => STATE_S_ESTABLISH_SEND_DATA, event => EV_HAS_DATA_TO_SEND, action => ACTION_SET_DEVICE_TO_SENDER  );
	$self->_t( from => STATE_N_IDLE, to => STATE_R_AWAKE, event => EV_RECEIVE_ENQ, action => ACTION_SET_DEVICE_TO_RECEIVER );

	# Receiver Device
	$self->_t( from => STATE_R_AWAKE, to => STATE_N_IDLE, event => EV_BUSY, action => [ ACTION_SET_DEVICE_TO_NEUTRAL, ACTION_SEND_NAK ] );
	$self->_t( from => STATE_R_AWAKE, to => STATE_R_WAITING, event => EV_NOT_BUSY, action => [ ACTION_SET_INITIAL_FN, ACTION_SEND_ACK, ACTION_RESET_RECEIVER_TIMER ] );

	$self->_t( from => STATE_R_WAITING, to => STATE_R_FRAME_RECEIVED, event => EV_GET_FRAME, action => ACTION_NOP );
	$self->_t( from => STATE_R_WAITING, to => STATE_N_IDLE, event => EV_RECEIVE_EOT_OR_TIME_OUT, action => ACTION_SET_DEVICE_TO_NEUTRAL );

	$self->_t( from => STATE_R_FRAME_RECEIVED, to => STATE_R_GOOD_FRAME, event => EV_GOOD_FRAME, action => ACTION_NOP );
	$self->_t( from => STATE_R_FRAME_RECEIVED, to => STATE_R_WAITING, event => EV_BAD_FRAME, action => [ ACTION_RESET_RECEIVER_TIMER, ACTION_SEND_NAK ] );

	$self->_t( from => STATE_R_GOOD_FRAME, to => STATE_R_WAITING, event => EV_NOT_HAS_DATA_TO_SEND, action => [ ACTION_INCREMENT_FN, ACTION_RESET_RECEIVER_TIMER, ACTION_SEND_ACK ] );
	$self->_t( from => STATE_R_GOOD_FRAME, to => STATE_R_SEND_DATA, event => EV_HAS_DATA_TO_SEND, action => ACTION_NOP );

	$self->_t( from => STATE_R_SEND_DATA, to => STATE_R_WAITING, event => EV_ANY, action => [ ACTION_INCREMENT_FN, ACTION_RESET_RECEIVER_TIMER, ACTION_SEND_EOT ] );

	# Sending Device
	$self->_t( from => STATE_S_ESTABLISH_SEND_DATA, to => STATE_S_ESTABLISH_WAITING, event => EV_ESTABLISHMENT_TIMERS_TIMED_OUT, action => [ ACTION_SET_INITIAL_FN, ACTION_SEND_ENQ, ACTION_RESET_SENDER_TIMER ] );
	$self->_t( from => STATE_S_ESTABLISH_SEND_DATA, to => STATE_S_ESTABLISH_CONTENTION_BUSY, event => EV_ESTABLISHMENT_TIMERS_RUNNING, action => ACTION_NOP );

	$self->_t( from => STATE_S_ESTABLISH_CONTENTION_BUSY, to => STATE_N_IDLE, event => EV_ANY, action => ACTION_SET_DEVICE_TO_NEUTRAL );

	$self->_t( from => STATE_S_ESTABLISH_WAITING, to => STATE_S_TRANSFER_SETUP_NEXT_FRAME, event => EV_RECEIVE_ACK, action => ACTION_RESET_RETRY_COUNT );
	$self->_t( from => STATE_S_ESTABLISH_WAITING, to => STATE_S_ESTABLISH_CONTENTION_BUSY, event => EV_RECEIVE_ENQ_OR_NAK, action => ACTION_RESET_CONTENTION_BUSY_TIMER );
	$self->_t( from => STATE_S_ESTABLISH_WAITING, to => STATE_N_IDLE, event => EV_TIMED_OUT, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );

	$self->_t( from => STATE_S_TRANSFER_SETUP_NEXT_FRAME, to => STATE_N_IDLE, event => EV_NOT_HAS_DATA_TO_SEND, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );
	$self->_t( from => STATE_S_TRANSFER_SETUP_NEXT_FRAME, to => STATE_S_TRANSFER_FRAME_READY, event => EV_HAS_DATA_TO_SEND, action => ACTION_SETUP_NEXT_FRAME );

	$self->_t( from => STATE_S_TRANSFER_FRAME_READY, to => STATE_S_TRANSFER_WAITING, event => EV_ANY, action => [ ACTION_SEND_FRAME, ACTION_RESET_SENDER_TIMER ] );

	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_S_TRANSFER_SETUP_OLD_FRAME, event => EV_RECEIVE_NAK_OR_FAIL, action => ACTION_INCREMENT_RETRY_COUNT );
	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_S_TRANSFER_SETUP_NEXT_FRAME, event => EV_RECEIVE_ACK, action => [ ACTION_RESET_RETRY_COUNT, ACTION_INCREMENT_FN ] );
	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_S_TRANSFER_INTERRUPT, event => EV_RECEIVE_EOT, action => [ ACTION_RESET_SENDER_TIMER, ACTION_REQUEST_INTERRUPT ] );
	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_N_IDLE, event => EV_TIMED_OUT, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );

	$self->_t( from => STATE_S_TRANSFER_SETUP_OLD_FRAME, to => STATE_S_TRANSFER_FRAME_READY, event => EV_CAN_RETRY, action =>  ACTION_SETUP_OLD_FRAME);
	$self->_t( from => STATE_S_TRANSFER_SETUP_OLD_FRAME, to => STATE_N_IDLE, event => EV_NO_CAN_RETRY, action =>  [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );

	$self->_t( from => STATE_S_TRANSFER_INTERRUPT, to => STATE_S_TRANSFER_SETUP_NEXT_FRAME, event => EV_INTERRUPT_IGNORE, action => [ ACTION_RESET_RETRY_COUNT, ACTION_INCREMENT_FN ]);
	$self->_t( from => STATE_S_TRANSFER_INTERRUPT, to => STATE_N_IDLE, event => EV_INTERRUPT_ACCEPT_OR_TIME_OUT, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ]);
}

sub reset {
	my ($self, $context) = @_;
	$self->session_state( STATE_N_IDLE );
	$self->_set_device_to_neutral($context);
}

sub _set_device_to_sender {
	my ($self, $context) = @_;
	$context->device_type( DEVICE_SENDER );
}

sub _set_device_to_receiver {
	my ($self, $context) = @_;
	$context->device_type( DEVICE_RECEIVER );
}

sub _set_device_to_neutral {
	my ($self, $context) = @_;
	$context->device_type( DEVICE_NEUTRAL );
}

sub _has_data_to_send {
	my ($self, $context) = @_;
	# TODO
	$context->has_data;
}

sub _on_receive_enq {
	...
}

sub _on_is_busy {
	...
}

sub _on_not_busy {
	...
}

1;
