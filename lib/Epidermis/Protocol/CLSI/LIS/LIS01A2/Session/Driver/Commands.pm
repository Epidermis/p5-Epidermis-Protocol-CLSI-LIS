package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Commands;
# ABSTRACT: A library of commands

use Const::Exporter default => [
	CMD_STEP_UNTIL_IDLE => 'step-until-idle',
	CMD_STEP_UNTIL     => 'step',
	CMD_SLEEP          => 'sleep',
	CMD_SEND_MSG       => 'send-message',
];

1;
