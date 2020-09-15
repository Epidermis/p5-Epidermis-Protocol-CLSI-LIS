use Modern::Perl;
package Epidermis::Lab::CLSI::LIS::Types;
# ABSTRACT: Type library for LIS standards

use Type::Library 0.008 -base,
	-declare => [qw(
	)];
use Type::Utils -all;

use Types::Common::Numeric qw(IntRange);

declare "FrameNumber", parent => IntRange[0, 7];

1;
