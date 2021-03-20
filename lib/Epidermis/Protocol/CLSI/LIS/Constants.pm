package Epidermis::Protocol::CLSI::LIS::Constants;
# ABSTRACT: Constants for protocol

use Modern::Perl;

use Const::Exporter
constants => [
	ENCODING => 'iso-8859-1',

	STX => "\x02", # (START OF TEXT) Message start token.
	ETX => "\x03", # (END OF TEXT) Message end token.
	EOT => "\x04", # (END OF TRANSMISSION) ASTM session termination token.
	ENQ => "\x05", # (ENQUIRY) ASTM session initialization token.
	ACK => "\x06", # (ACKNOWLEDGE) Command accepted token.
	NAK => "\x15", # (NEGATIVE ACKNOWLEDGE) Command rejected token.
	ETB => "\x17", # (END OF TRANSMISSION BLOCK) Message chunk end token.

	RECORD_SEP    => "\x0D", # \r # (CARRIAGE RETURN) Message records delimiter.
	FIELD_SEP     => "\x7C", # |  # (VERTICAL LINE) Record fields delimiter.
	REPEAT_SEP    => "\x5C", # \  # (REVERSE SOLIDUS) Delimiter for repeated fields.
	COMPONENT_SEP => "\x5E", # ^  # (CIRCUMFLEX ACCENT) Field components delimiter.
	ESCAPE_SEP    => "\x26", # &  # (AMPERSAND) Date escape token.

	LF  => "\x0A", # (LINE FEED)
	CR  => "\x0D", # (CARRIAGE RETURN)


	# The frame number begins at 1 with the first frame of the Transfer phase.
	LIS01A2_FIRST_FRAME_NUMBER => 1,

	# Maximum number of retries for sending frame on sender device.
	LIS01A2_MAX_RETRIES => 6,
];

use Const::Exporter
constants => [
	LIS_DEBUG => $ENV{EPIDERMIS_PROTOCOL_CLSI_LIS_DEBUG} // 0,
];

1;
