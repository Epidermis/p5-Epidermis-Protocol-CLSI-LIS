#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';

use Epidermis::Lab::CLSI::LIS::LIS02A2;
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
		is scalar ('Epidermis::Lab::CLSI::LIS::LIS02A2::Record::'.$a)->_fields,
			$b,
			"Field count for $a"
	} @RECORD_TYPE_TO_FIELD_COUNT;
};

done_testing;
