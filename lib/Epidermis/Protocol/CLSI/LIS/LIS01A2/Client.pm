package Epidermis::Protocol::CLSI::LIS::LIS01A2::Client;
# ABSTRACT: A client for LIS01A2

use Mu;
use namespace::autoclean;

extends 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';

use Data::Dumper;

use boolean;

with qw( Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::EventEmitter );

1;
