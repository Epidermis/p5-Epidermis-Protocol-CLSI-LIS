use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::RequestInformation;
# ABSTRACT: Request Information Record
### LIS02A2: 11 Request Information Record

use Moo;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 11.1 Record Type ID
### 5.5.6 Request Information Record (Q)
record_type_id 'Q';

### LIS02A2: 11.2 Sequence Number
field 'sequence';
### LIS02A2: 11.3 Starting Range ID Number
field 'start_range_id';
### LIS02A2: 11.4 Ending Range ID Number
field 'end_range_id';
### LIS02A2: 11.5 Universal Test ID
field 'universal_test_id';
### LIS02A2: 11.6 Nature of Request Time Limits
field 'timestamp_nature';
### LIS02A2: 11.7 Beginning Request Results Date and Time
field 'start_results_timestamp';
### LIS02A2: 11.8 Ending Request Results Date and Time
field 'end_results_timestamp';
### LIS02A2: 11.9 Requesting Physician Name
field 'requesting_physician';
### LIS02A2: 11.10 Requesting Physician Telephone Number
field 'requesting_physician_telephone';
### LIS02A2: 11.11 User Field Number 1
field 'user_field_1';
### LIS02A2: 11.12 User Field Number 2
field 'user_field_2';
### LIS02A2: 11.13 Request Information Status Codes
field 'status_codes';

1;
