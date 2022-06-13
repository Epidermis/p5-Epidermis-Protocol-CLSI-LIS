#!/usr/bin/env perl

package MyTest;
use lib 't/lib';
use Test2::Roo;
use MooX::ShortHas;

lazy simulator_events => sub {
	[
		[  'sim-step-n'  , 4 ]
	]
};

with 'Test::SessionSim';

run_me;

done_testing;
