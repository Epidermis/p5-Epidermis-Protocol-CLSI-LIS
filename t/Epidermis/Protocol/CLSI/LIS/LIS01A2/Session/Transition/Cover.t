#!/usr/bin/env perl

package MyTest;
use lib 't/lib';
use Test2::Roo;
use MooX::ShortHas;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::TimerFactory';

lazy client_steps => sub {
	[
		[ STATE_N_IDLE , 'send-message'  , LIS01A2::Message->create_message( 'Hello world' ) ],
		[ STATE_N_IDLE , 'step-until-idle' ],
	]
};

lazy simulator_steps => sub {
	[
		[ STATE_N_IDLE , 'step' ],
		[ STATE_R_GOOD_FRAME, 'sleep', TimerFactory->new->duration_sender + 1 ],
		[ STATE_R_GOOD_FRAME , 'step-until-idle' ],
	]
};

with 'Test::SessionSim';

run_me;

done_testing;
