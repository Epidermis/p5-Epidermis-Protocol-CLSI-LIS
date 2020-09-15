use Modern::Perl;
package Epidermis::Lab::CLSI::LIS::LIS02A2;
# ABSTRACT: Data protocol

# 6 Message Header Record ..........................................................................................................11
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::MessageHeader;
# 7 Patient Information Record......................................................................................................13
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::PatientInformation;
# 8 Test Order Record....................................................................................................................17
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::TestOrder;
# 9 Result Record...........................................................................................................................22
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::Result;
# 10 Comment Record .....................................................................................................................24
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::Comment;
# 11 Request Information Record ....................................................................................................25
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::RequestInformation;
# 12 Message Terminator Record ....................................................................................................27
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::MessageTerminator;
# 13 Scientific Record......................................................................................................................28
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::Scientific;
# 14 Manufacturer Information Record ...........................................................................................30
use Epidermis::Lab::CLSI::LIS::LIS02A2::Record::ManufacturerInformation;


1;
