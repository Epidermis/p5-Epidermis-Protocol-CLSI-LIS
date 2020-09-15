#!/usr/bin/env perl

use Test::Most tests => 3;

use Epidermis::Lab::CLSI::LIS::Constants qw(STX);
use aliased 'Epidermis::Lab::CLSI::LIS::LIS01A2::Frame';

subtest "Check frame creation" => sub {
	my $content = "test";

	my $frame = Frame->new(
		content => $content,
	);

	my $roundtrip_frame;
	lives_ok {
		$roundtrip_frame = Frame->parse_frame_data( $frame->frame_data );
	} 'Parse frame data to create roundtrip frame';

	is $roundtrip_frame->content, $content, 'Content of roundtrip';

	is $frame->checksum, $roundtrip_frame->checksum, 'Matching checksum';

	lives_ok {
		Frame->parse_frame_data( 'junk' . $frame->frame_data );
	} 'Parse frame data with junk before <STX>';
	throws_ok {
		Frame->parse_frame_data( 'junk' . $frame->frame_data . 'junk' );
	} qr/Expected end of data/;
};

subtest "Parsing error detection" => sub {
	my $frame = Frame->new;

	note "<STX>";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 1) )
	} qr/Expected frame number/;

	###

	note "<STX> 8";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 1) . '8' )
	} qr/Frame number invalid/;

	###

	note "<STX> FN";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 2) )
	} qr/Expected end-of-block character/;

	###

	note "<STX> FN <ETX>";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 3) )
	} qr/Expected checksum/;
	note "<STX> FN <ETX> C1";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 4) )
	} qr/Expected checksum/;
	note "<STX> FN <ETX> C1 Z";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 4) . 'Z' )
	} qr/Expected checksum/;

	###

	note "<STX> FN <ETX> C1 C2";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 5) )
	} qr/Expected CRLF/;
	note "<STX> FN <ETX> C1 C2 <CR>";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 6) )
	} qr/Expected CRLF/;

	note "<STX> FN <ETX> C1 C2 <CR> <LF>";
	lives_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 7) )
	} 'Full frame data';

	note "<STX> FN <ETX> C1 C2 <CR> <LF> junk";
	throws_ok {
		Frame->parse_frame_data( substr($frame->frame_data, 0, 7) . 'junk' )
	} qr/Expected end of data/;

	note "<STX> 2 data <STX>";
	throws_ok {
		Frame->parse_frame_data( "\x022data\x02" )
	} qr/Expected end-of-block character/;
	note "<STX> 2 data <ETX>";
	throws_ok {
		Frame->parse_frame_data( "\x022data\x03" )
	} qr/Expected checksum/;
};

subtest "Incorrect frame number" => sub {
	throws_ok {
		Frame->new(
			frame_number => 8,
		);
	} qr/FrameNumber/;
};

done_testing;
