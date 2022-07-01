package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;
# ABSTRACT: A library of commands

use Devel::StrictMode;
use Types::Standard qw(Enum);
use boolean;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event);

use Module::Load;
use Data::Dumper;

use Log::Any qw($log);

use Exporter 'import';
our @EXPORT = qw(
	StepUntilIdle
	StepUntil
	SleepPlus
	SendMsg
	SendMsgWithSingleFrame
	SendMsgWithMultipleFrames
	EnableCorruption
	DisableCorruption
	TestTransition
	TestLastFrameGood
	TestLastFrameBad
	TestRetryCount
);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::TestMessages';

use MooX::Struct -retain,
Command => [
	qw( description code ),
	run => sub {
		my ($self, $simulator, $session) = @_;
		$_[0]->code->( @_ );
	},
];
our $Command = Command;

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
	my $message = TestMessages->new->single_frame;
	Command->new(
		description => "Send single frame message",
		code => SendMsg( $message )->code,
	);
}

sub SendMsgWithMultipleFrames {
	my ($count) = @_;
	$count = 1 unless defined $count;
	my $message = TestMessages->new->multiple_frames($count);
	Command->new(
		description => "Send message with $count frames",
		code => SendMsg( $message )->code,
	);
}

sub _SetCorruptFlag {
	my ($flag) = @_;
	Command->new(
		description => "@{[ $flag ? 'Enable' : 'Disable' ]} corruption flag",
		code => sub {
			my ($self, $simulator, $session) = @_;
			$session->should_corrupt_frame_data( $flag );
			Future->done;
		},
	);
}

sub EnableCorruption {
	return _SetCorruptFlag(true);
}

sub DisableCorruption {
	return _SetCorruptFlag(false);
}

sub TestTransition {
	my ($event) = @_;
	Command->new(
		description => "Test that the last transition was $event",
		code => sub {
			my ($self, $simulator, $session) = @_;
			load Test2::V0, qw/is/;
			Future->done(
				is($simulator->transitions->[-1]->transition, $event, "@{[ $session->name ]}| Transition $event into state @{[ $session->session_state ]}")
			);
		},
	);
}

sub _TestLastFrame {
	my ($type, $data) = @_;
	(Enum['good','bad'])->assert_valid($type) if STRICT;
	my $printable_data = $data =~ s/([^[:print:]])/sprintf("\\x%02x", ord($1))/ger;
	Command->new(
		description => "Test that last frame is $type and has data $printable_data",
		code => sub {
			my ($self, $simulator, $session) = @_;
			load Test2::V0, qw/is subtest/;
			subtest("@{[ $session->name ]}| Test frame" => sub {
				my $last_frame = $simulator->frame_data->[-1];
				is( $last_frame->[0], ($type eq 'good' ? EV_GOOD_FRAME : EV_BAD_FRAME ) , "Frame is $type" );
				my $data_dump = do {
					local $Data::Dumper::Terse = 1;
					local $Data::Dumper::Indent = 0;
					local $Data::Dumper::Useqq = 1;
					Dumper($data);
				};
				is( $last_frame->[1], $data, "Frame data is $data_dump" );
			});
			Future->done;
		},
	);
}

sub TestLastFrameGood {
	my ($data) = @_;
	return _TestLastFrame( 'good', $data );
}

sub TestLastFrameBad {
	my ($data) = @_;
	return _TestLastFrame( 'bad', $data );
}

sub TestRetryCount {
	my ($current_try) = @_;
	Command->new(
		description => "Test retry count",
		code => sub {
			my ($self, $simulator, $session) = @_;
			load Test2::V0, qw/is/;
			is($session->_retries, $current_try,
				"@{[ $session->name ]}| Retry count @{[ $current_try ]}/@{[ $session->max_retries ]}");
			Future->done;
		},
	);
}

1;
