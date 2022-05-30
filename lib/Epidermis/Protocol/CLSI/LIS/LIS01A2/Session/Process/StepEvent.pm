package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEvent;
# ABSTRACT: Event for a step of the state-machine

use Mu;
use namespace::autoclean;
use MooX::Should;

extends 'Beam::Event';

ro state_transition => (
	should => $Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine::StateTransition->TYPE_TINY,
	handles => [qw(from transition to)],
);

1;
