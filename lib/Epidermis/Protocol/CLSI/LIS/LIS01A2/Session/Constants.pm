package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants;
# ABSTRACT: Constants for session internals

use Modern::Perl;

our @_ENUM_SYSTEM = qw(SYSTEM_INSTRUMENT SYSTEM_COMPUTER);
our @_ENUM_DEVICE = qw(DEVICE_SENDER DEVICE_RECEIVER DEVICE_NEUTRAL);

# STATE_N           : neutral
# STATE_R           : receiver
# STATE_S_ESTABLISH : sender (establishment phase)
# STATE_S_TRANSFER  : sender (transfer phase)
our @_ENUM_STATE  =
	qw(
		STATE_N_IDLE

		STATE_R_AWAKE
		STATE_R_WAITING
		STATE_R_FRAME_RECEIVED
		STATE_R_SEND_DATA

		STATE_S_ESTABLISH_SEND_DATA
		STATE_S_ESTABLISH_CONTENTION_BUSY
		STATE_S_ESTABLISH_WAITING

		STATE_S_TRANSFER_SETUP_NEXT_FRAME
		STATE_S_TRANSFER_FRAME_READY
		STATE_S_TRANSFER_WAITING
		STATE_S_TRANSFER_SETUP_OLD_FRAME
		STATE_S_TRANSFER_INTERRUPT
	);

use Const::Exporter
enum_system => [
	(
	map {
		$_ => lc( $_ =~ s/^SYSTEM_//r )
	} @_ENUM_SYSTEM,
	),
	'@ENUM_SYSTEM' => [ @_ENUM_SYSTEM ],
],
enum_device => [
	(
	map {
		$_ => lc( $_ =~ s/^DEVICE_//r )
	} @_ENUM_DEVICE,
	),
	'@ENUM_DEVICE' => [ @_ENUM_DEVICE ],
],
enum_state => [
	(
	map {
		$_ => lc( $_ =~ s/^STATE_//r )
	} @_ENUM_STATE,
	),
	'@ENUM_STATE' => [ @_ENUM_STATE ],
],
;

1;
