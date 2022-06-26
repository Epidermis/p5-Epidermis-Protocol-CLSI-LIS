package Test::SessionSim::FromDataFile;
# ABSTRACT: Read data file to load testing steps

use Test2::V0;
use Test2::Roo;
use MooX::ShortHas;
use Path::Tiny;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;

ro 'data_path';

use Import::Into;

sub import {
	my $caller = scalar caller;
	Test2::V0->import::into($caller);
}

lazy _data => sub {
	do "". path($_[0]->data_path)->absolute;
};

lazy local_steps => sub { $_[0]->_data->{local}; };
lazy remote_steps => sub { $_[0]->_data->{remote}; };

before setup => sub {
	note "Testing steps: ", $_[0]->data_path;
};

with 'Test::SessionSim';

1;
