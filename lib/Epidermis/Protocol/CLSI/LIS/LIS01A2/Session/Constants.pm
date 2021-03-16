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
		STATE_R_GOOD_FRAME
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

our @_ENUM_EVENT = qw(
	EV_ANY

	EV_HAS_DATA_TO_SEND_SENDER

	EV_HAS_DATA_TO_SEND_RECEIVER
	EV_NOT_HAS_DATA_TO_SEND_RECEIVER

	EV_TRANSFER_DONE
	EV_NOT_TRANSFER_DONE

	EV_RECEIVE_ENQ
	EV_RECEIVE_ENQ_OR_NAK

	EV_RECEIVE_NAK_OR_FAIL

	EV_RECEIVE_EOT
	EV_RECEIVE_EOT_OR_TIME_OUT

	EV_BUSY
	EV_NOT_BUSY

	EV_GET_FRAME

	EV_GOOD_FRAME
	EV_BAD_FRAME

	EV_ESTABLISHMENT_TIMERS_RUNNING
	EV_ESTABLISHMENT_TIMERS_TIMED_OUT

	EV_TIMED_OUT

	EV_RECEIVE_ACK

	EV_CAN_RETRY
	EV_NO_CAN_RETRY

	EV_INTERRUPT_IGNORE
	EV_INTERRUPT_ACCEPT_OR_TIME_OUT
);

our @_ENUM_ACTION = qw(
	ACTION_NOP

	ACTION_SET_DEVICE_TO_SENDER
	ACTION_SET_DEVICE_TO_RECEIVER
	ACTION_SET_DEVICE_TO_NEUTRAL

	ACTION_SEND_NAK
	ACTION_SEND_ACK
	ACTION_SEND_EOT

	ACTION_SET_INITIAL_FN
	ACTION_INCREMENT_FN
	ACTION_RESET_RECEIVER_TIMER

	ACTION_SEND_ENQ
	ACTION_RESET_SENDER_TIMER

	ACTION_RESET_CONTENTION_BUSY_TIMER

	ACTION_SETUP_NEXT_FRAME
	ACTION_SETUP_OLD_FRAME

	ACTION_RESET_RETRY_COUNT
	ACTION_INCREMENT_RETRY_COUNT

	ACTION_SEND_FRAME

	ACTION_REQUEST_INTERRUPT
);

use Const::Exporter;

Const::Exporter->import(
enum_system => [
	(
	our %_ENUM_SYSTEM_VALUES = map {
		$_ => lc( $_ =~ s/^SYSTEM_//r )
	} @_ENUM_SYSTEM,
	),
	'@ENUM_SYSTEM' => [ values %_ENUM_SYSTEM_VALUES ],
],
enum_device => [
	(
	our %_ENUM_DEVICE_VALUES = map {
		$_ => lc( $_ =~ s/^DEVICE_//r )
	} @_ENUM_DEVICE,
	),
	'@ENUM_DEVICE' => [ values %_ENUM_DEVICE_VALUES ],
],
enum_state => [
	(
	our %_ENUM_STATE_VALUES = map {
		$_ => lc( $_ =~ s/^STATE_//r )
	} @_ENUM_STATE,
	),
	'@ENUM_STATE' => [ values %_ENUM_STATE_VALUES ],
],
enum_event => [
	(
	our %_ENUM_EVENT_VALUES = map {
		$_ => lc( $_ =~ s/^EV_//r )
	} @_ENUM_EVENT,
	),
	'@ENUM_EVENT' => [ values %_ENUM_EVENT_VALUES ],
],
enum_action => [
	(
	our %_ENUM_ACTION_VALUES = map {
		$_ => lc( $_ =~ s/^ACTION_//r )
	} @_ENUM_ACTION,
	),
	'@ENUM_ACTION' => [ values %_ENUM_ACTION_VALUES ],
],
);

Const::Exporter->import(
enum_device => [
	DEVICE__START_DEVICE => DEVICE_NEUTRAL(),
],
enum_state => [
	STATE__START_STATE => STATE_N_IDLE(),
],
);

## Timer durations in seconds as specified in standard
Const::Exporter->import(
timer => [
	TIMER_DURATION_SENDER => 15,
	TIMER_DURATION_RECEIVER => 30,
	TIMER_DURATION_CONTENTION_INSTRUMENT => 1,
	TIMER_DURATION_CONTENTION_COMPUTER => 20,
	TIMER_DURATION_BUSY => 10,
]
);

1;
