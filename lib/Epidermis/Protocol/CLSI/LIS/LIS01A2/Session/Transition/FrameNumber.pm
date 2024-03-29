package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::FrameNumber;
# ABSTRACT: Frame number actions

use Mu::Role;
use namespace::autoclean;
use Future::AsyncAwait;
use MooX::Should;

use Epidermis::Protocol::CLSI::LIS::Types qw(FrameNumber);
use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS01A2_FIRST_FRAME_NUMBER);
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame;

has _frame_number => (
	is => 'rw',
	should => FrameNumber,
);

sub _increment_frame_number {
	my ($self) = @_;
	$self->_frame_number( Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame
		->_compute_next_frame_number(
			$self->_frame_number
	));
}

### ACTIONS

async sub do_set_initial_fn {
	$_[0]->_frame_number( LIS01A2_FIRST_FRAME_NUMBER );
}

async sub do_increment_fn {
	$_[0]->_increment_frame_number;
}

1;
