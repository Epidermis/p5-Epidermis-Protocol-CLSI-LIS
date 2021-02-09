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
