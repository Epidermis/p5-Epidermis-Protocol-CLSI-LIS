package Test::TimerFactory::Factor;
# ABSTRACT: Role to transform the duration of timers

use Mu::Role;
use MooX::Should;
use Types::Common::Numeric qw(PositiveNum);

has factor => (
	is => 'rw',
	should => PositiveNum,
	default => sub { 1 },
);

for my $duration_attr (qw(
	duration_receiver
	duration_sender
	duration_contention_instrument
	duration_contention_computer
	duration_busy
)) {
	around $duration_attr => sub {
		my ( $orig, $self, @args ) = @_;

		$self->$orig(@args) * $self->factor;
	};
}

1;
