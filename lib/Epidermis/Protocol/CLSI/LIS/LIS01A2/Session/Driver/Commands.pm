package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;
# ABSTRACT: A library of commands

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Exporter 'import';
our @EXPORT = qw(
	CMD_STEP_UNTIL_IDLE
	CMD_STEP_UNTIL
	CMD_SLEEP
	CMD_SEND_MSG
);

use MooX::Struct Command => [
	qw( description code ),
	run => sub {
		my ($self, $simulator, $session) = @_;
		$_[0]->code->( @_ );
	},
];

sub CMD_STEP_UNTIL_IDLE {
	Command->new(
		description => 'Process events until idle',
		code => sub {
			my ($self, $simulator, $session) = @_;
			$session->_process_until_state( STATE_N_IDLE );
		},
	);
}

sub CMD_STEP_UNTIL {
	my ($state) = @_;
	Command->new(
		description => "Process events until $state",
		code => sub {
			my ($self, $simulator, $session) = @_;
			$session->_process_until_state( $state );
		},
	);
}

sub CMD_SLEEP {
	my ($duration) = @_;
	Command->new(
		description => "Sleep for $duration seconds",
		code => sub {
			my ($self, $simulator, $session) = @_;
			Future::IO->sleep($duration);
		},
	);
}

sub CMD_SEND_MSG {
	my ($message) = @_;
	Command->new(
		description => "Send message $message",
		code => sub {
			my ($self, $simulator, $session) = @_;
			$session->send_message( $message );
			Future->done;
		},
	);
}

1;
