package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::Comment;
# ABSTRACT: Comment Record
### LIS02A2: 10 Comment Record

use Moo;
use namespace::autoclean;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 10.1 Record Type ID
### 5.5.5 Comment Record (C)
record_type_id 'C';

record_level undef;

### LIS02A2: 10.2 Sequence Number
field 'sequence';
### LIS02A2: 10.3 Comment Source
field 'source';
### LIS02A2: 10.4 Comment Text
field 'text';
### LIS02A2: 10.5 Comment Type
field 'type';

1;
