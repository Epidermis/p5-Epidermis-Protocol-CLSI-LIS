package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::EventEmitter;
# ABSTRACT: Role to step through processing session events

use Mu::Role;
use namespace::autoclean;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEvent';

use Future::AsyncAwait;
use Future::Utils qw(repeat);

with qw(Beam::Emitter);

requires qw(session_state step);

async sub process_until_idle {
	my ($self) = @_;

	die "Invalid start state: @{[ $self->session_state ]}"
		if $self->session_state ne STATE_N_IDLE;

	my $r_f = repeat {
		my $f = $self->step
			->on_fail(sub {
				my ($f1) = @_;
				$self->_logger->trace( "Failed: " . Dumper($f1) );
			})->followed_by(sub {
				my ($f1) = @_;
				$self->emit( 'step',
					class => StepEvent,
					state_transition => $f1->get,
				);
				Future->done;
			})->else(sub {
				Future->done;
			});
	} until => sub {
		$self->session_state eq STATE_N_IDLE
	};

	await $r_f;
}

1;
