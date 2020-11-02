use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageTerminator;
# ABSTRACT: Message Terminator Record
### LIS02A2: 12 Message Terminator Record

use Moo;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 12.1 Record Type ID
### This record type is coded as L.
record_type_id 'L';

record_level 0;

### LIS02A2: 12.2 Sequence Number
field 'sequence';
### LIS02A2: 12.3 Termination Code
field 'code';

1;
