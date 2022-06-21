package Epidermis::Protocol::CLSI::LIS::LIS01A2::Simulator;
# ABSTRACT: Simulator for LIS01A2 communication

use Mu;
use namespace::autoclean;
use MooX::Should;

use Future::AsyncAwait;

use Types::Standard  qw(InstanceOf);
use Types::Common::Numeric qw(PositiveInt);

use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS_DEBUG);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';

with qw( MooX::Role::Logger );

ro session =>  (
	should => InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Session'],
	required => 1,
);

ro transitions => (
	default => sub { [] },
);

1;
