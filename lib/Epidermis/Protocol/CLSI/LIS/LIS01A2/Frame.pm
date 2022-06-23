package Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame;
# ABSTRACT: LIS01A2 Frame - a subdivision of a message

use utf8;
use feature qw(state);

use Mu;
use namespace::autoclean;
use MooX::Enumeration;

use Convert::ASCIInames ();

use failures qw(LIS01A2::Frame::Parse LIS01A2::Frame::Checksum);

use Epidermis::Protocol::CLSI::LIS::Types qw(FrameNumber);
use Types::Standard qw(Enum Str);

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	LIS01A2_FIRST_FRAME_NUMBER
	STX ETB ETX
	CR LF
);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame::Constants
	qw(:frame_type);

use Const::Fast;

const our %FRAME_TYPE_TO_TX_CONTROL => (
	FRAME_TYPE_INTERMEDIATE ,=> ETB,
	FRAME_TYPE_END ,=> ETX,
);

# Restricted characters of data content (LIS01A2 § 6.6.2)
const our @RESTRICTED => map { chr(Convert::ASCIInames::ASCIIordinal($_)) }
	qw(SOH STX ETX EOT ENQ ACK DLE NAK SYN ETB LF DC1 DC2 DC3 DC4);

=attr frame_data

Frame data

  is => lazy

=cut

lazy frame_data => sub {
	my ($self) = @_;
	join "", (
		STX,
		$self->_fn_to_eob_string,
		$self->checksum,
		CR, LF,
	);
}, isa => Str;

=attr frame_number

  FrameNumber

=cut
has frame_number => (
	is => 'ro',
	required => 0,
	isa => FrameNumber,
	default => sub { LIS01A2_FIRST_FRAME_NUMBER },
);

lazy next_frame_number => sub {
	my ($self) = @_;
	$self->_compute_next_frame_number(
		$self->frame_number
	);
};

sub _compute_next_frame_number {
	my ($class, $frame_number) = @_;
	($frame_number + 1) % 8;
}

=attr content

  Str

=cut
has content => (
	is => 'ro',
	required => 0,
	isa => Str,
	default => sub { "" },
);

=attr type

  Enum[ intermediate, end ]

=cut
has type => (
	is => 'ro',
	required => 0,
	isa => Enum[     FRAME_TYPE_INTERMEDIATE, FRAME_TYPE_END   ],
	handles => [ qw/         is_intermediate          is_end / ],
	default => sub { FRAME_TYPE_END },
);

lazy _fn_to_eob_string => sub {
	my ($self) = @_;
	join("",
		$self->frame_number,
		$self->content,
		$FRAME_TYPE_TO_TX_CONTROL{ $self->type },
	)
};

=attr checksum

  is => lazy

=cut
lazy checksum => sub {
	my ($self) = @_;
	$self->_compute_checksum(
		$self->_fn_to_eob_string
	);
};

sub _compute_checksum {
	my ($class, $substring) = @_;
	sprintf( "%02X", unpack( "%8C*", $substring ) % 256 );
}

sub _chars_to_hex_re_str {
	my ($class, @chars) = @_;
	my $hex_re = join '', map { sprintf "\\x%02x", ord($_) } @chars;
	$hex_re;
}

sub _chars_to_hex_re {
	my ($class, @chars) = @_;
	my $hex_re = $class->_chars_to_hex_re_str(@chars);
	qr/$hex_re/;
}

=classmethod parse_frame_data


=cut
sub parse_frame_data {
	my ($class, $frame_data) = @_;

	my ($fn, $content, $type);
	my $eob;

	# Only data from STX onwards (LIS01A2 § 6.5.1.1)
	state $stx_re = qr/
		(?<STX> @{[ STX ]})
	/xsa;
	if( $frame_data =~ /$stx_re/g ) {
		# nop
	} else {
		failure::LIS01A2::Frame::Parse->throw('Expected STX');
	}

	state $frame_number_re = qr/
		\G
		(?<frame_number> \d )
	/xsa;
	if( $frame_data =~ /$frame_number_re/g ) {
		$fn = $+{'frame_number'};
		failure::LIS01A2::Frame::Parse->throw("Frame number invalid: $fn")
			unless FrameNumber->check($fn);
	} else {
		failure::LIS01A2::Frame::Parse->throw("Expected frame number");
	}

	state $content_re = qr/
		\G
		(?<content> [^@{[ $class->_chars_to_hex_re_str(@RESTRICTED) ]}]*)
	/xsa;
	if( $frame_data =~ /$content_re/g ) {
		$content = $+{content}
	} else {
		failure::LIS01A2::Frame::Parse->throw("Expected content");
	}

	state $end_of_block_re = qr/
		\G
		(?<end_of_block> [@{[ $class->_chars_to_hex_re_str(values %FRAME_TYPE_TO_TX_CONTROL) ]}])
	/xsa;
	if( $frame_data =~ /$end_of_block_re/g ) {
		$eob = $+{end_of_block};
		$type = { reverse %FRAME_TYPE_TO_TX_CONTROL }->{ $eob };
	} else {
		failure::LIS01A2::Frame::Parse->throw("Expected end-of-block character");
	}

	state $checksum_re = qr/
		\G
		(?<checksum> [0-9A-F]{2})
	/xsa;
	if( $frame_data =~ /$checksum_re/g ) {
		my $got_checksum = $+{checksum};
		my $expected_checksum = $class->_compute_checksum(join("", $fn, $content, $eob));

		# check checksum
		failure::LIS01A2::Frame::Checksum->throw({
			msg => "Checksum failure",
			payload => { got => $got_checksum, expected => $expected_checksum },
		}) if $got_checksum ne $expected_checksum;
	} else {
		failure::LIS01A2::Frame::Parse->throw("Expected checksum");
	}

	state $crlf_re = qr/
		\G
		(?<CRLF> @{[ $class->_chars_to_hex_re(CR , LF) ]})
	/xsa;
	if( $frame_data =~ /$crlf_re/g ) {
		# nop
	} else {
		failure::LIS01A2::Frame::Parse->throw("Expected CRLF");
	}

	failure::LIS01A2::Frame::Parse->throw("Expected end of data")
		unless pos($frame_data) == length($frame_data);

	my $frame = $class->new(
		frame_number => $fn,
		content => $content,
		type => $type,
	);

	$frame;
}

1;

=head1 DESCRIPTION

From § 6.3.1.2 of LIS01-A2:

=for html <blockquote>

The frame structure is illustrated as follows:

    <STX> FN text <ETB> C1 C2 <CR> <LF> ← intermediate frame
    <STX> FN text <ETX> C1 C2 <CR> <LF> ← end frame

where:

     <STX>               =         Start of Text transmission control character
     FN                  =          single digit Frame Number 0 to 7
     text                =         Data Content of Message
     <ETB>               =         End of Transmission Block transmission control
                                   character
     <ETX>               =         End of Text transmission control character
     C1                  =          most significant character of checksum 0 to 9 and A
                                   to F
     C2                  =          least significant character of checksum 0 to 9 and A
                                   to F
     <CR>                =         Carriage Return ASCII character
     <LF>                =         Line Feed ASCII character

=for html </blockquote>

=cut
