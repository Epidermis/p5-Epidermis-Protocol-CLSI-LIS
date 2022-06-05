package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Processable;
# ABSTRACT: A role to process steps of state machine

use Mu::Role;
use namespace::autoclean;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Future::AsyncAwait;
use Future::Utils qw(repeat);

requires qw(session_state step);

sub process_step {
	my ($self) = @_;
	$self->step;
}

async sub process_until_idle {
	my ($self) = @_;

	die "Invalid start state: @{[ $self->session_state ]}"
		if $self->session_state ne STATE_N_IDLE;

	my $r_f = repeat {
		my $f = $self->process_step
			->on_fail(sub {
				my ($f1) = @_;
				$self->_logger->trace( "Failed: " . Dumper($f1) );
			})
			->else(sub {
				Future->done;
			});
	} until => sub {
		$self->session_state eq STATE_N_IDLE
	};

	await $r_f;
}

1;