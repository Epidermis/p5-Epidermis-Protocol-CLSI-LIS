package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Any;
# ABSTRACT: Special transition for any event

use Moo::Role;
use namespace::autoclean;
use Future::AsyncAwait;
use boolean;

### ACTIONS

async sub do_nop {
	true;
}

### EVENTS

async sub event_on_any {
	true;
}

1;
