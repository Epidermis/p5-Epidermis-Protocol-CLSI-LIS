package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;



sub send_message {

}

sub _send_frame {
	...
}

with qw(
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Context
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable

	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Device
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Control
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::FrameNumber
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Retry
);

1;
