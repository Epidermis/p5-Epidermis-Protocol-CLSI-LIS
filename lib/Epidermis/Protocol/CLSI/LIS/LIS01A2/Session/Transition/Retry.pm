package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Retry;
# ABSTRACT: Retry transitions

use Moo::Role;
use Future::AsyncAwait;

sub do_reset_retry_count {
	...
}

sub do_increment_retry_count {
	...
}

async sub event_on_can_retry {
}

async sub event_on_no_can_retry {
}

1;
