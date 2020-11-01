use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::Result;
# ABSTRACT: Result Record
### LIS02A2: 9     Result Record

use Moo;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 9.1    Record Type ID
### 5.5.4 Result Record (R)
record_type_id 'R';

record_level 3;

### LIS02A2: 9.2    Sequence Number
field 'sequence';
### LIS02A2: 9.3    Universal Test ID
field 'universal_test_id';
### LIS02A2: 9.4    Data or Measurement Value
field 'value';
### LIS02A2: 9.5    Units
field 'units';
### LIS02A2: 9.6    Reference Ranges
field 'reference_ranges';
### LIS02A2: 9.7    Result Abnormal Flags
field 'abnormal_result_flags';
### LIS02A2: 9.8    Nature of Abnormality Testing
field 'abnormality_test_nature';
### LIS02A2: 9.9    Result Status
field 'status';
### LIS02A2: 9.10 Date of Change in Instrument Normative Values or Units
field 'instrument_normative_change_timestamp';
### LIS02A2: 9.11 Operator Identification
field 'operator_id';
### LIS02A2: 9.12 Date/Time Test Started
field 'start_timestamp';
### LIS02A2: 9.13 Date/Time Test Completed
field 'end_timestamp';
### LIS02A2: 9.14 Instrument Identification
field 'instrument_id';

1;
