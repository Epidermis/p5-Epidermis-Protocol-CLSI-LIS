package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Any;
# ABSTRACT: Special transition for any event

use Moo::Role;
use Future::AsyncAwait;
use boolean;

async sub event_on_any {
	true;
}

1;
