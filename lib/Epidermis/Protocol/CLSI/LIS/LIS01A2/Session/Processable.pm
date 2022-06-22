package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Processable;
# ABSTRACT: A role to process steps of state machine

use Mu::Role;
use namespace::autoclean;

use Devel::StrictMode;
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);
use Types::Standard qw(Enum);

use Future::AsyncAwait;
use Future::Utils qw(repeat);

requires qw(session_state step);

sub process_step {
	my ($self) = @_;
	$self->step;
}

my $EnumState = Enum[ @ENUM_STATE ];
async sub _process_until_state {
	my ($self, $state) = @_;
	$EnumState->assert_valid( $state ) if STRICT;

	my $r_f = repeat {
		my $f = $self->process_step
			->on_fail(sub {
				my ($f1) = @_;
				$self->_logger->trace( $self->_logger_name_prefix . "Failed: " . Dumper($f1) );
			})
			->else(sub {
				Future->done;
			});
	} until => sub {
		$self->session_state eq $state
	};

	await $r_f;
}

async sub process_until_idle {
	my ($self) = @_;

	die "Invalid start state: @{[ $self->session_state ]}"
		if $self->session_state ne STATE_N_IDLE;

	await $self->_process_until_state( STATE_N_IDLE );
}

1;
