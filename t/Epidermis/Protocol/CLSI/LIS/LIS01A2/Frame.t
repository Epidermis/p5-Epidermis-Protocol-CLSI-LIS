#!/usr/bin/env perl

use Test2::V0;
plan tests => 6;

use Epidermis::Protocol::CLSI::LIS::Constants qw(STX ETX ETB CR LF);
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame';

use Data::Hexdumper ();
use boolean;

subtest "Check frame creation" => sub {
	my $content = "test";

	my $frame = Frame->new(
		content => $content,
	);

	my $roundtrip_frame;
	ok lives {
		$roundtrip_frame = Frame->parse_frame_data( $frame->frame_data );
	}, 'Parse frame data to create roundtrip frame' or note $@;

	is $roundtrip_frame->content, $content, 'Content of roundtrip';

	is $frame->checksum, $roundtrip_frame->checksum, 'Matching checksum';

	ok lives {
		Frame->parse_frame_data( 'junk' . $frame->frame_data );
	}, 'Parse frame data with junk before <STX>' or note $@;
	like dies {
		Frame->parse_frame_data( 'junk' . $frame->frame_data . 'junk' );
	}, qr/Expected end of data/, 'Exception on data after CRLF';

	ok Frame->new->is_end, 'End frame is default';
	ok Frame->new( type => 'intermediate' )->is_intermediate,
		'Create intermediate frame';
	ok Frame->new( type => 'end' )->is_end,
		'Explicitly create end frame';

	is Frame->new( content => "A|B|C|D\x0d" )->checksum,
		'BF', 'Got checksum';
};

subtest "Parse good frame data" => sub {
	# Example frame via <https://hendricksongroup.com/code_003.aspx>
	my $frame = Frame->parse_frame_data( join "", (
		STX,
		"5R|2|^^^1.0000+950+1.0|15|||^5^||V||34001637|20080516153540|20080516153602|34001637\x0d",
		ETX,
		'3D', # checksum
		CR, LF
	));
	ok $frame->is_end, 'parsed end frame';
	is $frame->checksum, '3D', 'checksum';
};

subtest "Parsing error detection" => sub {
	my $frame = Frame->new;

	note "<STX>";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 1) )
	}, qr/Expected frame number/;

	###

	note "<STX> 8";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 1) . '8' )
	}, qr/Frame number invalid/;

	###

	note "<STX> FN";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 2) )
	}, qr/Expected end-of-block character/;

	###

	note "<STX> FN <ETX>";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 3) )
	}, qr/Expected checksum/;
	note "<STX> FN <ETX> C1";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 4) )
	}, qr/Expected checksum/;
	note "<STX> FN <ETX> C1 Z";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 4) . 'Z' )
	}, qr/Expected checksum/;

	###

	note "<STX> FN <ETX> C1 C2";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 5) )
	}, qr/Expected CRLF/;
	note "<STX> FN <ETX> C1 C2 <CR>";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 6) )
	}, qr/Expected CRLF/;

	note "<STX> FN <ETX> C1 C2 <CR> <LF>";
	ok lives {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 7) )
	}, 'Full frame data';

	note "<STX> FN <ETX> C1 C2 <CR> <LF> junk";
	like dies {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 7) . 'junk' )
	}, qr/Expected end of data/;

	note "<STX> 2 data <STX>";
	like dies {
		Frame->parse_frame_data( "\x022data\x02" )
	}, qr/Expected end-of-block character/;
	note "<STX> 2 data <ETX>";
	like dies {
		Frame->parse_frame_data( "\x022data\x03" )
	}, qr/Expected checksum/;
};

subtest "Incorrect frame number" => sub {
	like dies {
		Frame->new(
			frame_number => 8,
		);
	}, qr/FrameNumber/;
};

subtest "Frame type" => sub {
	my $test_text = "test";

	subtest "End frame" => sub {
		my $end_test_frame = Frame->new(
			type => 'end',
			content => $test_text );
		is substr( $end_test_frame->frame_data, -5, 1 ), ETX,
			'end frame has ETX';
		ok Frame->parse_frame_data($end_test_frame->frame_data)
			->is_end,
			'end frame round-trips as end frame';
		note "End frame data: ", Data::Hexdumper::hexdump(
			data => $end_test_frame->frame_data,
			suppress_warnings => true );
	};

	subtest "Intermediate frame" => sub {
		my $int_test_frame = Frame->new(
			type => 'intermediate',
			content => $test_text );
		is substr( $int_test_frame->frame_data, -5, 1 ), ETB,
			'intermediate frame has ETB';
		ok Frame->parse_frame_data($int_test_frame->frame_data)
			->is_intermediate,
			'intermediate frame round-trips as intermediate frame';
		note "Intermediate frame data: ", Data::Hexdumper::hexdump(
			data => $int_test_frame->frame_data,
			suppress_warnings => true );
	};
};

subtest "Frame number sequence" => sub {
	my $frame = Frame->new;
	is $frame->frame_number, 1, 'FN: starts at 1';
	is $frame->next_frame_number, 2, 'FN: 1 -> 2';

	my $frame_wrap = Frame->new( frame_number => 7 );
	is $frame_wrap->next_frame_number, 0, 'FN: 7 -> 0';
};

done_testing;
