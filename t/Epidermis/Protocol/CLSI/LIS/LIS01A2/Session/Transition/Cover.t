#!/usr/bin/env perl

package Test::SM::SenderTimesOut;
use lib 't/lib';
use Test2::Roo;
use MooX::ShortHas;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;

lazy local_steps => sub {
	[
		[ STATE_N_IDLE , SendMsgWithSingleFrame() ],
		[ STATE_N_IDLE , StepUntilIdle() ],
		[ STATE_N_IDLE , TestTransition(EV_TIMED_OUT) ],
	]
};

lazy remote_steps => sub {
	[
		[ STATE_N_IDLE , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME, SleepPlus('sender') ],
		[ STATE_R_GOOD_FRAME , StepUntilIdle() ],
	]
};

with 'Test::SessionSim';

run_me;

done_testing;
