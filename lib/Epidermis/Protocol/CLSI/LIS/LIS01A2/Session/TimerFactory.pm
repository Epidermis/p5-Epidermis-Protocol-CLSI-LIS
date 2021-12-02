package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::TimerFactory;
# ABSTRACT: Factory for timers needed in various state transitions

use Mu;
use Future;
use Future::IO;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :timer);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Timer';

sub at_initial {
	return Timer->new(
		type => 'initial',
		future => Future->done,
	);
}

ro duration_receiver => (
	default => sub { TIMER_DURATION_RECEIVER },
);

sub at_receiver {
	my ($self) = @_;
	return Timer->new(
		type => 'receiver',
		future => Future::IO
			->sleep($self->duration_receiver)
			->set_label('receiver timer'),
	);
}

ro duration_sender => (
	default => sub { TIMER_DURATION_SENDER },
);

sub at_sender {
	my ($self) = @_;
	return Timer->new(
		type => 'sender',
		future => Future::IO
			->sleep($self->duration_sender)
			->set_label('sender timer'),
	);
}

ro duration_contention_instrument => (
	default => sub { TIMER_DURATION_CONTENTION_INSTRUMENT },
);

sub at_contention_instrument {
	my ($self) = @_;
	return Timer->new(
		type => 'contention',
		future => Future::IO
			->sleep( $self->duration_contention_instrument )
			->set_label('contention timer'),
	);
}

ro duration_contention_computer => (
	default => sub { TIMER_DURATION_CONTENTION_COMPUTER },
);

sub at_contention_computer {
	my ($self) = @_;
	return Timer->new(
		type => 'contention',
		future => Future::IO
			->sleep( $self->duration_contention_computer )
			->set_label('contention timer'),
	);
}

sub at_contention_for_system {
	my ($self, $system) = @_;
	if( $system eq SYSTEM_INSTRUMENT ) {
		return $self->at_contention_instrument;
	} else {
		return $self->at_contention_computer;
	}
}

ro duration_busy => (
	default => sub { TIMER_DURATION_BUSY },
);

sub at_busy {
	my ($self) = @_;
	return Timer->new(
		type => 'busy',
		future => Future::IO
			->sleep($self->duration_busy)
			->set_label('busy timer'),
	);
}

1;
