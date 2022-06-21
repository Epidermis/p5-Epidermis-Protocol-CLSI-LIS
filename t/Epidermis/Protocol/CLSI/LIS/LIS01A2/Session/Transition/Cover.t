#!/usr/bin/env perl

package MyTest;
use lib 't/lib';
use Test2::Roo;
use MooX::ShortHas;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::TimerFactory';
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;

lazy local_steps => sub {
	[
		[ STATE_N_IDLE , CMD_SEND_MSG()  , LIS01A2::Message->create_message( 'Hello world' ) ],
		[ STATE_N_IDLE , CMD_STEP_UNTIL_IDLE() ],
	]
};

lazy remote_steps => sub {
	[
		[ STATE_N_IDLE , CMD_STEP_UNTIL() ],
		[ STATE_R_GOOD_FRAME, CMD_SLEEP(), TimerFactory->new->duration_sender + 1 ],
		[ STATE_R_GOOD_FRAME , CMD_STEP_UNTIL_IDLE() ],
	]
};

with 'Test::SessionSim';

run_me;

done_testing;
