package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::ManufacturerInformation;
# ABSTRACT: Manufacturer Information Record
### LIS02A2: 14 Manufacturer Information Record

use Moo;
use namespace::autoclean;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### 5.5.8 Manufacturer Information Record (M)
record_type_id 'M';

record_level undef;

#  Sequence number—As defined in Section 5.6.7.
field 'sequence';

1;
