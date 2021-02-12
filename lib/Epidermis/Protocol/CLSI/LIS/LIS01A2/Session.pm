package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session;
# ABSTRACT: LIS01A2::Session - a total unit of communication activity

use Mu;

use Future::AsyncAwait;
use Future::IO;


sub _send_frame {
	...
}

async sub _recv_data {
	my ($self) = @_;
	Future::IO->sysread( $self->connection->handle, 4096 );
}

async sub _send_data {
	my ($self, $data) = @_;
	Future::IO->syswrite( $self->connection->handle , $data );
}

async sub event_on_good_frame {
}
async sub event_on_get_frame {
}
async sub event_on_busy {
}
async sub event_on_not_busy {
}
async sub event_on_has_data_to_send {
}
async sub event_on_any {
}
async sub event_on_interrupt_ignore {
}
async sub event_on_interrupt_accept_or_time_out {
}
async sub event_on_timed_out {
}
async sub event_on_no_can_retry {
}
async sub event_on_not_has_data_to_send {
}
async sub event_on_can_retry {
}
async sub event_on_bad_frame {
}
async sub event_on_establishment_timers_running {
}
async sub event_on_establishment_timers_timed_out {
}


with qw(
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Context
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::StateMachine
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable

	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Device
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Control
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::FrameNumber
	Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Retry
);

1;
