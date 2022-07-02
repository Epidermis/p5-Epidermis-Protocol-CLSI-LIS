package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine;
# ABSTRACT: A state machine for the session

use Moo;
use namespace::autoclean;
use MooX::Should;
use Sub::HandlesVia;
use Devel::StrictMode;
use Sub::Trigger::Lock qw( Lock unlock );
use List::AllUtils qw(first);

use Types::Standard qw(Map Enum Dict ArrayRef);
use Types::Common::Numeric qw(PositiveOrZeroInt PositiveInt);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event :enum_action);

# Document layout of state map.
our $StateMapType = Map[
	# From state
	Enum[@ENUM_STATE],
	Map[
		# To state
		Enum[@ENUM_STATE],
		Dict[
			# Transition
			event  => Enum[@ENUM_EVENT],
			action => ArrayRef[Enum[@ENUM_ACTION]],
			id     => PositiveInt,
		]
	]
];

has _state_map => (
	is => 'ro',
	default => sub { +{} },
	trigger => Lock,
	should => $StateMapType,
);

has _transition_counter => (
	is => 'ro',
	default => sub { 0 },
	should => PositiveOrZeroInt,
	handles_via => 'Number',
	handles => {
		_next_transition_counter => [ add => 1 ],
	},
);

sub _t {
	my ($self, %args) = @_;

	my $from = $args{from} or die "Transition requires 'from' argument";
	my $to = $args{to} or die "Transition requires 'to' argument";
	my $event = $args{event} or die "Transition requires 'event' argument";
	my $action = $args{action} or die "Transition requires 'action' argument";

	my $sm = $self->_state_map;

	die "Already have transition from $from to $to"
		if exists $sm->{ $from }{ $to };

	my $existing_to_for_event = $self->_get_transition_from_state_for_event($from, $event);
	die "Already have event: [ $from ] -- $event -- [ $existing_to_for_event ], can not add event to [ $to ]"
		if $existing_to_for_event;

	$sm->{ $from }{ $to } = {
		event  => $event,
		action => ref $action ? $action : [ $action ],
		id     => $self->_next_transition_counter,
	};
}

sub _get_transition_from_state_for_event {
	my ($self, $from, $event ) = @_;

	my $sm = $self->_state_map;
	my $existing_to_for_event = first { $sm->{$from}{$_}{event} eq $event }
		keys %{ $sm->{ $from } };
}

sub events_for_state {
	my ($self, $state) = @_;
	my $sm = $self->_state_map;
	[ map { $sm->{$state}{$_}{event} }
		keys %{ $sm->{ $state } } ];
}

sub BUILD {
	my ($self, $args) = @_;

	my $unlock_state_map = unlock( $self->_state_map );

	# Neutral Device
	$self->_t( from => STATE_N_IDLE, to => STATE_S_ESTABLISH_SEND_DATA, event => EV_HAS_DATA_TO_SEND_SENDER, action => ACTION_SET_DEVICE_TO_SENDER  );
	$self->_t( from => STATE_N_IDLE, to => STATE_R_AWAKE, event => EV_RECEIVE_ENQ, action => ACTION_SET_DEVICE_TO_RECEIVER );

	# Receiver Device
	$self->_t( from => STATE_R_AWAKE, to => STATE_N_IDLE, event => EV_BUSY, action => [ ACTION_SET_DEVICE_TO_NEUTRAL, ACTION_SEND_NAK ] );
	$self->_t( from => STATE_R_AWAKE, to => STATE_R_WAITING, event => EV_NOT_BUSY, action => [ ACTION_SET_INITIAL_FN, ACTION_SEND_ACK, ACTION_RESET_RECEIVER_TIMER ] );

	$self->_t( from => STATE_R_WAITING, to => STATE_R_FRAME_RECEIVED, event => EV_GET_FRAME, action => ACTION_NOP );
	$self->_t( from => STATE_R_WAITING, to => STATE_N_IDLE, event => EV_RECEIVE_EOT_OR_TIME_OUT, action => ACTION_SET_DEVICE_TO_NEUTRAL );

	$self->_t( from => STATE_R_FRAME_RECEIVED, to => STATE_R_GOOD_FRAME, event => EV_GOOD_FRAME, action => ACTION_NOP );
	$self->_t( from => STATE_R_FRAME_RECEIVED, to => STATE_R_WAITING, event => EV_BAD_FRAME, action => [ ACTION_RESET_RECEIVER_TIMER, ACTION_SEND_NAK ] );

	$self->_t( from => STATE_R_GOOD_FRAME, to => STATE_R_WAITING, event => EV_NOT_HAS_DATA_TO_SEND_RECEIVER, action => [ ACTION_INCREMENT_FN, ACTION_RESET_RECEIVER_TIMER, ACTION_SEND_ACK ] );
	$self->_t( from => STATE_R_GOOD_FRAME, to => STATE_R_SEND_DATA, event => EV_HAS_DATA_TO_SEND_RECEIVER, action => ACTION_NOP );

	$self->_t( from => STATE_R_SEND_DATA, to => STATE_R_WAITING, event => EV_ANY, action => [ ACTION_INCREMENT_FN, ACTION_RESET_RECEIVER_TIMER, ACTION_SEND_EOT ] );

	# Sending Device
	$self->_t( from => STATE_S_ESTABLISH_SEND_DATA, to => STATE_S_ESTABLISH_WAITING, event => EV_ESTABLISHMENT_TIMERS_TIMED_OUT, action => [ ACTION_SET_INITIAL_FN, ACTION_SEND_ENQ, ACTION_RESET_SENDER_TIMER ] );
	$self->_t( from => STATE_S_ESTABLISH_SEND_DATA, to => STATE_S_ESTABLISH_CONTENTION_BUSY, event => EV_ESTABLISHMENT_TIMERS_RUNNING, action => ACTION_NOP );

	$self->_t( from => STATE_S_ESTABLISH_CONTENTION_BUSY, to => STATE_N_IDLE, event => EV_ANY, action => ACTION_SET_DEVICE_TO_NEUTRAL );

	$self->_t( from => STATE_S_ESTABLISH_WAITING, to => STATE_S_TRANSFER_SETUP_NEXT_FRAME, event => EV_RECEIVE_ACK, action => [ ACTION_RESET_RETRY_COUNT, ACTION_SETUP_NEXT_FRAME ] );
	$self->_t( from => STATE_S_ESTABLISH_WAITING, to => STATE_S_ESTABLISH_CONTENTION_BUSY, event => EV_RECEIVE_ENQ_OR_NAK, action => ACTION_RESET_CONTENTION_BUSY_TIMER );
	$self->_t( from => STATE_S_ESTABLISH_WAITING, to => STATE_N_IDLE, event => EV_TIMED_OUT, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );

	$self->_t( from => STATE_S_TRANSFER_SETUP_NEXT_FRAME, to => STATE_N_IDLE, event => EV_TRANSFER_DONE, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );
	$self->_t( from => STATE_S_TRANSFER_SETUP_NEXT_FRAME, to => STATE_S_TRANSFER_FRAME_READY, event => EV_NOT_TRANSFER_DONE, action => ACTION_NOP );

	$self->_t( from => STATE_S_TRANSFER_FRAME_READY, to => STATE_S_TRANSFER_WAITING, event => EV_ANY, action => [ ACTION_SEND_FRAME, ACTION_RESET_SENDER_TIMER ] );

	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_S_TRANSFER_SETUP_OLD_FRAME, event => EV_RECEIVE_NAK_OR_FAIL, action => ACTION_INCREMENT_RETRY_COUNT );
	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_S_TRANSFER_SETUP_NEXT_FRAME, event => EV_RECEIVE_ACK, action => [ ACTION_RESET_RETRY_COUNT, ACTION_INCREMENT_FN, ACTION_SETUP_NEXT_FRAME ] );
	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_S_TRANSFER_INTERRUPT, event => EV_RECEIVE_EOT, action => [ ACTION_RESET_SENDER_TIMER, ACTION_REQUEST_INTERRUPT ] );
	$self->_t( from => STATE_S_TRANSFER_WAITING, to => STATE_N_IDLE, event => EV_TIMED_OUT, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );

	$self->_t( from => STATE_S_TRANSFER_SETUP_OLD_FRAME, to => STATE_S_TRANSFER_FRAME_READY, event => EV_CAN_RETRY, action =>  ACTION_SETUP_OLD_FRAME);
	$self->_t( from => STATE_S_TRANSFER_SETUP_OLD_FRAME, to => STATE_N_IDLE, event => EV_NO_CAN_RETRY, action =>  [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ] );

	$self->_t( from => STATE_S_TRANSFER_INTERRUPT, to => STATE_S_TRANSFER_SETUP_NEXT_FRAME, event => EV_INTERRUPT_IGNORE, action => [ ACTION_RESET_RETRY_COUNT, ACTION_INCREMENT_FN, ACTION_SETUP_NEXT_FRAME ]);
	$self->_t( from => STATE_S_TRANSFER_INTERRUPT, to => STATE_N_IDLE, event => EV_INTERRUPT_ACCEPT_OR_TIME_OUT, action => [ ACTION_SEND_EOT, ACTION_SET_DEVICE_TO_NEUTRAL ]);

	$StateMapType->assert_valid( $self->_state_map ) if STRICT;
}

sub to_plantuml {
	my ($self) = @_;

	my $map = $self->_state_map;

	my $plantuml;
	$plantuml .= "\@startuml\n\n";
	$plantuml .= "[*] --> @{[ STATE__START_STATE ]}\n";
	for my $from ( sort keys %$map ) {
		for my $to ( sort keys %{ $map->{$from} } ) {
			my $event = $map->{$from}{$to}{event};
			my $action = $map->{$from}{$to}{action};
			my $action_italics = join '\n', map { "//$_//" } @$action;
			$plantuml .= "$from --> $to : $event\\n$action_italics";
			$plantuml .= "\n";
		}
	}

	$plantuml .= "\n";
	$plantuml .= "\@enduml\n";

	return $plantuml;
}

sub process_event {
	my ($self, $current_state, $event) = @_;

	my $to = $self->_get_transition_from_state_for_event( $current_state, $event );

	die "No transition from state [ $current_state ] via event $event" unless $to;

	return { to => $to,
		( map {
			$_ => $self->_state_map->{ $current_state }{ $to }{$_}
		} qw(action id) )
	};
}

1;
