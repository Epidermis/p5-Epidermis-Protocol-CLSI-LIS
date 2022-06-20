package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Drivable;
# ABSTRACT: Role for session that can be driven by a sequence of commands

use Mu::Role;
use Types::Standard qw(ArrayRef);
use Future::Utils qw(repeat try_repeat);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;

ro commands => (
	should => ArrayRef,
);

sub process_commands {
	my $session = shift;
	my $events = $session->commands;
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

with qw( Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Processable );

1;
