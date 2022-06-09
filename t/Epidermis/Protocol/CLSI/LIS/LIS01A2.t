#!/usr/bin/env perl

use Test2::V0;
plan tests => 1;

use lib 't/lib';

use autodie;

use aliased 'Epidermis::Lab::Connection::Serial' => 'Connection::Serial';
use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';

subtest "Test transmission" => sub {
	pass;
};

done_testing;
