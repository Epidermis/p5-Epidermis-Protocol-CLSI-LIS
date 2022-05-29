package Epidermis::Protocol::CLSI::LIS::LIS01A2::Client;
# ABSTRACT: A client for LIS01A2

use Mu;
use namespace::autoclean;

extends 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state);

use Future::AsyncAwait;
use Future::Utils qw(fmap_void repeat);
use Data::Dumper;

use boolean;

async sub do_until_neutral_state {
	my ($self) = @_;
	my $session = $self;

	die "Invalid start state: @{[ $session->session_state ]}"
		if $session->session_state ne STATE_N_IDLE;

	my $count_in_idle = 0;
	my $step_count = 0;
	my $r_f = repeat {
		my $f = $session->step
			->on_fail(sub {
				my ($f1) = @_;
				$session->_logger->trace( "Failed: " . Dumper($f1) );
			})->followed_by(sub {
				my ($f1) = @_;
				$count_in_idle++ if $session->session_state eq STATE_N_IDLE;
				++$step_count;
				$session->_logger->tracef(
					"[%s] Step %d (I:%d): %s :: %s",
					$session->name,
					$step_count,
					$count_in_idle,
					$f1->get,
					$session,
				);
				Future->done;
			})->else(sub {
				Future->done;
			});
	} until => sub {
		$count_in_idle == 1;
	};

	await $r_f;
}


1;
