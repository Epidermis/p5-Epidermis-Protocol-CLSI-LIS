package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Timer;
# ABSTRACT: A specific type of timer

use Mu;
use Types::Standard qw(Str InstanceOf);
use Future::AsyncAwait;
use boolean;

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

async sub timed_out {
	my ($self) = @_;

	my $timed_out;
	await $self->future->on_cancel(sub {
		$timed_out = false;
	})->on_done(sub {
		$timed_out = true;
	});

	return $timed_out;
}

1;
