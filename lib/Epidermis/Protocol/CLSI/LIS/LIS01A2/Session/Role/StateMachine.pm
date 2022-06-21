package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine;
# ABSTRACT: Session state machine role

use Mu::Role;
use namespace::autoclean;
use MooX::Enumeration;

use Data::Dumper;

use Types::Standard qw(Enum);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine';

use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS_DEBUG);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Future::AsyncAwait;

use MooX::Struct -retain,
StateTransition => [
	qw( id from transition to ),
	TO_STRING => sub {
		my ($self) = @_;
		"[@{[ $self->id ]}: @{[ $self->from ]} ] -- @{[ $self->transition ]} --> [ @{[ $self->to ]} ]"
	}
];
our $StateTransition = StateTransition;

has state_machine => (
	is => 'ro',
	default => sub { StateMachine->new; },
);

has session_state => (
	is => 'rw',
	isa => Enum[ @ENUM_STATE ],
	init_arg => undef,
	default => sub { STATE__START_STATE },
);

sub STATE_TO_STRING {
	my ($self) = @_;
	"[ State: <@{[ $self->session_state ]}> ]";
}

async sub step {
	my ($self) = @_;
	my $events = $self->state_machine->events_for_state( $self->session_state );
	do {
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		$self->_logger->debug( $self->_logger_name_prefix . "State @{[ $self->session_state ]}: Events " . Dumper([ sort { $a cmp $b } @$events ]) )
	} if LIS_DEBUG && $self->_logger->is_debug;
	my @events_cb = @{ $self->_event_dispatch_table }{ @$events };

	my $transition_event = await Future->needs_any( map {
		my $idx = $_;
		my $f = $events_cb[$idx]->($self)
			->transform( done => sub { $events->[$idx] } )
			->set_label( $events->[$idx] )
	} 0..@events_cb-1 )->set_label( LIS_DEBUG ? "$self : events @$events" : "$self : events" );

	my $from = $self->session_state;
	my $transition_data = $self->state_machine->process_event(
		$self,
		$transition_event
	);

	do {
		$self->_logger->debug( $self->_logger_name_prefix . "Transition: [ @{[ $from ]} ] -- @{[ $transition_event ]} --> [ @{[ $transition_data->{to} ]} ]" )
	} if LIS_DEBUG && $self->_logger->is_debug;

	$self->session_state( $transition_data->{to} );

	my @actions = @{ $transition_data->{action} };
	my $actions_done = Future->needs_all( map {
		my $action = $_;
		my $f = $self->_action_dispatch_table->{$action}->($self)
			->set_label($action)
	} @actions)->set_label( LIS_DEBUG ? "actions: @actions" : 'actions' );

	await $actions_done->followed_by( sub { $self->_reset_after_step; Future->done->set_label('reset after step') } );

	return StateTransition[
		$transition_data->{id},
		$from,
		$transition_event,
		$transition_data->{to}
	];
}

sub _reset_after_step { }

1;
