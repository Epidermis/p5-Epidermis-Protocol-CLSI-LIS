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
	qw(:enum_state);

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

ro transitions => (
	default => sub { [] },
);

sub BUILD {
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
		push @{ $self->transitions }, $event->state_transition;
	});
}

sub process_commands {
	my ($self) = @_;
	my $session = $self->session;
	my $events = $self->commands;
	my ($last_idx, $last_event, @last_data);
	my $sim_process_events_f = try_repeat {
		my $idx = shift;
		my ($state, $event_name, @data) = @{ $events->[$idx] };

		if( $session->session_state eq $state ) {
			$last_event = $event_name;
			@last_data  = @data;
		}

		if( $last_event eq CMD_STEP_UNTIL_IDLE ) {
			print "[Process @{[ $session->name ]} until idle", "]\n";
			$session->_process_until_state( STATE_N_IDLE );
		} elsif( $last_event eq CMD_STEP_UNTIL ) {
			print "[Process @{[ $session->name ]} until ", $events->[$idx + 1][0], "]\n";
			$session->_process_until_state( $events->[$idx + 1][0]);
		} elsif( $last_event eq CMD_SLEEP ) {
			print "[sleep for ", $last_data[0], "]\n";
			Future::IO->sleep($last_data[0]);
		} elsif( $last_event eq CMD_SEND_MSG ) {
			print "[send message ", $last_data[0], "]\n";
			$session->send_message( $last_data[0] );
			Future->done;
		}
	} foreach => [ 0..@$events-1 ];
}

1;
