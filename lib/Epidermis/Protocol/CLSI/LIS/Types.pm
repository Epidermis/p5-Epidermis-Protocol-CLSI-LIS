use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::Types;
# ABSTRACT: Type library for LIS standards

use Type::Library 0.008 -base,
	-declare => [qw(
	)];
use Type::Utils -all;

use Types::Common::Numeric qw(IntRange PositiveOrZeroInt);
use Types::Standard        qw(StrMatch Maybe);

declare "FrameNumber", parent => IntRange[0, 7];

declare "SingleCharacter", parent => StrMatch[qr/\A[^\x0d]\z/];

declare "RecordType", parent => "SingleCharacter";

declare "RecordLevel", parent => Maybe[PositiveOrZeroInt];

declare "Separator", parent => "SingleCharacter";

1;
