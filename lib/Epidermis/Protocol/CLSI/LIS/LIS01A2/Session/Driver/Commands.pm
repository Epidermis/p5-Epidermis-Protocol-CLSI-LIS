package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;
# ABSTRACT: A library of commands

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Module::Load;

use Log::Any qw($log);

use Exporter 'import';
our @EXPORT = qw(
	StepUntilIdle
	StepUntil
	SleepPlus
	SendMsg
	SendMsgWithSingleFrame
	TestTransition
);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

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

sub SleepPlus {
	my ($duration_name, $add) = @_;
	$add = 1 unless defined $add;
	Command->new(
		description => "Sleep for duration $duration_name plus $add second(s)",
		code => sub {
			my ($self, $simulator, $session) = @_;
			my $duration_method = "duration_$duration_name";
			my $tf = $session->_timer_factory;
			if( my $meth = $tf->can($duration_method) ) {
				my $duration = $meth->($tf);
				my $sleep_for = $duration + $add;
				$log->tracef("Sleeping for %f second(s)", $sleep_for)
					if $log->is_trace;
				return Future::IO->sleep($sleep_for);
			} else {
				return Future->die( "unknown duration $duration_method" );
			}
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

sub SendMsgWithSingleFrame {
	my $message = LIS01A2::Message->create_message( 'Hello world' );
	Command->new(
		description => "Send single frame message",
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
