package Epidermis::Protocol::CLSI::LIS::LIS01A2::Simulator;
# ABSTRACT: Simulator for LIS01A2 communication

use Mu;
use namespace::autoclean;
use MooX::Should;

use Future::AsyncAwait;
use Future::Utils qw(repeat try_repeat);

use Types::Standard  qw(ConsumerOf ArrayRef);
use Types::Common::Numeric qw(PositiveInt);

use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS_DEBUG);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Drivable';

with qw( MooX::Role::Logger );

ro session =>  (
	should => ConsumerOf[Drivable],
	required => 1,
	coerce   => sub {
		if( ! $_[0]->DOES(Drivable) ) {
			Moo::Role->apply_roles_to_object( $_[0], Drivable);
		}
	},
);

ro commands => (
	should => ArrayRef,
);

ro [ qw(transitions frame_data) ] => (
	init_arg => undef,
	default => sub { [] },
	should => ArrayRef,
);

sub _apply_logger {
	my ($self) = @_;
	my $step_count = 0;
	my $log = $self->_logger;
	$self->session->on( step => sub {
		my ($event) = @_;
		++$step_count;
		$log->tracef(
			"[%s] Step %d: %s :: %s",
			$event->emitter->name,
			$step_count,
			$event->state_transition,
			$event->emitter,
		);
	});
}

sub _apply_transition_tracking {
	my ($self) = @_;
	$self->session->on( step => sub {
		my ($event) = @_;
		push @{ $self->transitions }, $event->state_transition;
	});
}

sub _apply_frame_data_tracking {
	my ($self) = @_;
	$self->session->on( step => sub {
		my ($event) = @_;
		if( $event->transition eq EV_GOOD_FRAME || $event->transition eq EV_BAD_FRAME ) {
			push @{ $self->frame_data },
				[
					$event->transition,
					$self->session->_current_receivable_message->_current_frame_data
				];
		}
	});

}

sub BUILD {
	my ($self) = @_;
	$self->_apply_logger;
	$self->_apply_transition_tracking;
	$self->_apply_frame_data_tracking;
}

sub process_commands {
	my ($self) = @_;
	my $session = $self->session;
	my $events = $self->commands;
	my $sim_process_events_f = repeat {
		my $event = shift;
		my ($state, $event_command) = @$event;
		if( $session->session_state eq $state ) {
			$self->_logger->tracef( "[ %s | %s ]",
				$self->session->name,
				$event_command->description
			);
			$event_command->run($self, $session);
		} else {
			Future->die( "unexpected state" );
		}
	} foreach => $events, while => sub { $_[0]->is_done };
}

1;
