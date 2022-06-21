package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Drivable;
# ABSTRACT: Role for session that can be driven by a sequence of commands

use Mu::Role;

with qw(
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Processable
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEventEmitter
);

1;
