#!/usr/bin/env perl

use Test2::V0;
plan tests => 3;

use lib 't/lib';
use StandardData;

use Epidermis::Protocol::CLSI::LIS::LIS02A2;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Codec;
use List::AllUtils qw(pairmap);

subtest "Check record field counts" => sub {
	my @RECORD_TYPE_TO_FIELD_COUNT = (
		'MessageHeader'           => 14, # 6.14 Date and Time of Message
		'PatientInformation'      => 35, # 7.35 Dosage Category
		'TestOrder'               => 31, # 8.4.31 Specimen Institution
		'Result'                  => 14, # 9.14 Instrument Identification
		'Comment'                 =>  5, # 10.5 Comment Type
		'RequestInformation'      => 13, # 11.13 Request Information Status Codes
		'MessageTerminator'       =>  3, # 12.3 Termination Code
		'Scientific'              => 21, # 13.21 Patient Race
		'ManufacturerInformation' =>  2, # Manufacturer-defined fields
	);


	pairmap {
		is scalar ('Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::'.$a)->_fields,
			$b,
			"Field count for $a"
	} @RECORD_TYPE_TO_FIELD_COUNT;
};

subtest "Check record level" => sub {
	my %LEVEL_TO_RECORD_TYPE = (
		# At level zero is the message header and message terminator.
		0 => [ qw(MessageHeader MessageTerminator) ],

		# At level one is the patient record, the request-information record, and the scientific record.
		1 => [ qw( PatientInformation RequestInformation Scientific ) ],

		# At level two is the test order record.
		2 => [ qw(TestOrder) ],

		# At level three is the result record.
		3 => [ qw(Result) ],

		# The comment and manufacturer information records do not have an assigned level.
		undef => [ qw(Comment ManufacturerInformation) ],
	);
	my %RECORD_TYPE_TO_LEVEL = map {
		my $level_str = $_;
		my $level = eval $level_str; ## no critic: ProhibitStringyEval

		map {
			my $record_type = $_;
			( $_ => $level )
		} @{ $LEVEL_TO_RECORD_TYPE{$level_str} };
	} keys %LEVEL_TO_RECORD_TYPE;

	pairmap {
		is scalar ('Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::'.$a)->_level,
			$b,
			"Level for $a"
	} %RECORD_TYPE_TO_LEVEL;
};

subtest "Standard data" => sub {
	my @data = @{ StandardData->lis02a2_standard_data };
	my @messages;
	for my $message (@data) {
		my $text = StandardData->lis02a2_standard_data_text_to_message_text($message->{text});
		my $lis_msg = Epidermis::Protocol::CLSI::LIS::LIS02A2::Message->create_message( $text );

		is $lis_msg->as_outline, $message->{text},
			"Message outline round-trip: $message->{id}";
	}
};

done_testing;
