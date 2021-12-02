package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Timer;
# ABSTRACT: A specific type of timer

use Mu;
use Types::Standard qw(Str InstanceOf);

=attr type

Type: C<Str>

The type of timer.

=cut

ro 'type' => ( isa => Str );

=attr future

Type: L<Future>

Represents the timer.

=cut
ro 'future' => (
	isa => InstanceOf['Future'],
);

1;
