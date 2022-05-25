package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Device;
# ABSTRACT: Device type actions

use Moo::Role;
use namespace::autoclean;
use Future::AsyncAwait;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_device);

requires 'device_type';

### ACTIONS

async sub do_set_device_to_sender {
	$_[0]->device_type( DEVICE_SENDER );
}

async sub do_set_device_to_receiver {
	$_[0]->device_type( DEVICE_RECEIVER );
}

async sub do_set_device_to_neutral {
	$_[0]->device_type( DEVICE_NEUTRAL );
}

1;
