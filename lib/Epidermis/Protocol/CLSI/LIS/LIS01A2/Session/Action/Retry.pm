package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Retry;
# ABSTRACT: Sender retry actions

use Moo::Role;

sub do_reset_retry_count {
	...
}

sub do_increment_retry_count {
	...
}

1;
