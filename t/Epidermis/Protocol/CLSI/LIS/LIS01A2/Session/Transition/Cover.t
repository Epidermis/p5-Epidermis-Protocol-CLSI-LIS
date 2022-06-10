#!/usr/bin/env perl

package MyTest;
use lib 't/lib';
use Test2::Roo;
with 'Test::SessionSim';

run_me;

done_testing;
