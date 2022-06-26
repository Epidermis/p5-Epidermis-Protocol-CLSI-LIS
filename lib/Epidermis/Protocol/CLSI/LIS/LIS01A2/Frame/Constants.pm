package Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame::Constants;
# ABSTRACT: Constants for frames

our @_ENUM_FRAME_TYPE = qw(
	FRAME_TYPE_INTERMEDIATE
	FRAME_TYPE_END
);
use Const::Exporter;
Const::Exporter->import(
frame_type => [
	(
	our %_ENUM_FRAME_TYPE_VALUES = map {
		$_ => lc( $_ =~ s/^FRAME_TYPE_//r )
	} @_ENUM_FRAME_TYPE,
	),
	'@ENUM_FRAME_TYPE' => [ values %_ENUM_FRAME_TYPE_VALUES ],
]);

1;
