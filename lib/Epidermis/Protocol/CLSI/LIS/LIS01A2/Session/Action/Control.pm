package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Action::Control;
# ABSTRACT: Control character actions

use Moo::Role;

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENQ
	EOT
	ACK NAK
);

requires 'connection';

sub do_send_enq {
	$_[0]->connection->handle->print( ENQ );
}

sub do_send_eot {
	$_[0]->connection->handle->print( EOT );
}

sub do_send_ack {
	$_[0]->connection->handle->print( ACK );
}

sub do_send_nak {
	$_[0]->connection->handle->print( NAK );
}

1;
