use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::TestOrder;
# ABSTRACT: Test Order Record
### LIS02A2: 8     Test Order Record

use Moo;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 8.4.1 Record Type ID
### 5.5.3 Test Order Record (O)
record_type_id 'O';

### LIS02A2: 8.4.2 Sequence Number
field 'sequence';
### LIS02A2: 8.4.3 Specimen ID
field 'specimen_id';
### LIS02A2: 8.4.4 Instrument Specimen ID
field 'instrument_specimen_id';
### LIS02A2: 8.4.5 Universal Test ID
field 'universal_test_id';
### LIS02A2: 8.4.6 Priority
field 'priority';
### LIS02A2: 8.4.7 Requested/Ordered Date and Time
field 'requested_timestamp';
### LIS02A2: 8.4.8 Specimen Collection Date and Time
field 'collection_timestamp';
### LIS02A2: 8.4.9 Collection End Time
field 'collection_end_timestamp';
### LIS02A2: 8.4.10 Collection Volume
field 'volume';
### LIS02A2: 8.4.11 Collector ID
field 'collector_id';
### LIS02A2: 8.4.12 Action Code
field 'action_code';
### LIS02A2: 8.4.13 Danger Code
field 'danger_code';
### LIS02A2: 8.4.14 Relevant Clinical Information
field 'clinical_info';
### LIS02A2: 8.4.15 Date/Time Specimen Received
field 'received_timestamp';

### LIS02A2: 8.4.16 Specimen Descriptor
field 'descriptor';
### LIS02A2: 8.4.16.1 Specimen Type
### LIS02A2: 8.4.16.2 Specimen Source

### LIS02A2: 8.4.17 Ordering Physician
field 'ordering_physician';
### LIS02A2: 8.4.18 Physician’s Telephone Number
field 'physician_telephone';
### LIS02A2: 8.4.19 User Field Number 1
field 'user_field_1';
### LIS02A2: 8.4.20 User Field Number 2
field 'user_field_2';
### LIS02A2: 8.4.21 Laboratory Field Number 1
field 'lab_field_1';
### LIS02A2: 8.4.22 Laboratory Field Number 2
field 'lab_field_2';
### LIS02A2: 8.4.23 Date/Time Results Reported or Last Modified
field 'modified_timestamp';
### LIS02A2: 8.4.24 Instrument Charge to Information System
field 'instrument_charge';
### LIS02A2: 8.4.25 Instrument Section ID
field 'instrument_section_id';
### LIS02A2: 8.4.26 Report Types
field 'report_types';
### LIS02A2: 8.4.27 Reserved Field
field 'reserved';
### LIS02A2: 8.4.28 Location of Specimen Collection
field 'specimen_collection_location';
### LIS02A2: 8.4.29 Nosocomial Infection Flag
field 'nosocomial_infection_flag';
### LIS02A2: 8.4.30 Specimen Service
field 'specimen_service';
### LIS02A2: 8.4.31 Specimen Institution
field 'specimen_institution';

1;
