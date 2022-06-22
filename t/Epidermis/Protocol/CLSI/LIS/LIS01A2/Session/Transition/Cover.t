#!/usr/bin/env perl

package MyTest;
use lib 't/lib';
use Test2::Roo;
use MooX::ShortHas;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event);
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::TimerFactory';
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;

lazy local_steps => sub {
	[
		[ STATE_N_IDLE , SendMsg( LIS01A2::Message->create_message( 'Hello world' ) ) ],
		[ STATE_N_IDLE , StepUntilIdle() ],
		[ STATE_N_IDLE , TestTransition(EV_TIMED_OUT) ],
	]
};

lazy remote_steps => sub {
	[
		[ STATE_N_IDLE , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME, Sleep(TimerFactory->new->duration_sender + 1) ],
		[ STATE_R_GOOD_FRAME , StepUntilIdle() ],
	]
};

with 'Test::SessionSim';

run_me;

done_testing;
