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

use Data::Dumper::Concise;

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
			->else_with_f( sub {
				my ($f1, $exception) = @_;
				$self->_logger->trace( $self->_logger_name_prefix . "Failed: " . Dumper($exception) );
				return $f1;
			})
	} until => sub {
		$_[0]->is_failed || $self->session_state eq $state
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
