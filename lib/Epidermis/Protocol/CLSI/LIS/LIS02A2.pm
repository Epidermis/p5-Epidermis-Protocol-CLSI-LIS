package Epidermis::Protocol::CLSI::LIS::LIS02A2;
# ABSTRACT: Data protocol

use strict;
use warnings;
use namespace::autoclean;

use Const::Fast;

const our @BASE_RECORD_TYPE_PACKAGES =>
	map {
		"Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::$_"
	} (
		# 6 Message Header Record ..........................................................................................................11
		'MessageHeader',
		# 7 Patient Information Record......................................................................................................13
		'PatientInformation',
		# 8 Test Order Record....................................................................................................................17
		'TestOrder',
		# 9 Result Record...........................................................................................................................22
		'Result',
		# 10 Comment Record .....................................................................................................................24
		'Comment',
		# 11 Request Information Record ....................................................................................................25
		'RequestInformation',
		# 12 Message Terminator Record ....................................................................................................27
		'MessageTerminator',
		# 13 Scientific Record......................................................................................................................28
		'Scientific',
		# 14 Manufacturer Information Record ...........................................................................................30
		'ManufacturerInformation',
	);

use Module::Load;
load $_ for @BASE_RECORD_TYPE_PACKAGES;

use Epidermis::Protocol::CLSI::LIS::LIS02A2::Message;

1;
