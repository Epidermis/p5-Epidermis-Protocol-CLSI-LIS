package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;
# ABSTRACT: A library of commands

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Module::Load;

use Exporter 'import';
our @EXPORT = qw(
	StepUntilIdle
	StepUntil
	Sleep
	SendMsg
	TestTransition
);

use MooX::Struct Command => [
	qw( description code ),
	run => sub {
		my ($self, $simulator, $session) = @_;
		$_[0]->code->( @_ );
	},
];

sub StepUntilIdle {
	Command->new(
		description => 'Process events until idle',
		code => sub {
			my ($self, $simulator, $session) = @_;
			$session->_process_until_state( STATE_N_IDLE );
		},
	);
}

sub StepUntil {
	my ($state) = @_;
	Command->new(
		description => "Process events until $state",
		code => sub {
			my ($self, $simulator, $session) = @_;
			$session->_process_until_state( $state );
		},
	);
}

sub Sleep {
	my ($duration) = @_;
	Command->new(
		description => "Sleep for $duration seconds",
		code => sub {
			my ($self, $simulator, $session) = @_;
			Future::IO->sleep($duration);
		},
	);
}

sub SendMsg {
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

sub TestTransition {
	my ($event) = @_;
	Command->new(
		description => "Test that the last transition was $event",
		code => sub {
			my ($self, $simulator, $session) = @_;
			load Test2::V0, qw/is/;
			Future->done(
				is($simulator->transitions->[-1]->transition, $event, "Transition $event")
			);
		},
	);
}

1;
