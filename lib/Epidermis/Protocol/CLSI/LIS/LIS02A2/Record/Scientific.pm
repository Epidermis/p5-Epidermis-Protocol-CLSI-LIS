use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::Scientific;
# ABSTRACT: Scientific Record
### LIS02A2: 13 Scientific Record

use Moo;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 13.1 Record Type ID
### 5.5.7 Scientific Record (S)
record_type_id 'S';

### LIS02A2: 13.2 Sequence Number
field 'sequence';
### LIS02A2: 13.3 Analytical Method
field 'analytical_method';
### LIS02A2: 13.4 Instrumentation
field 'instrumentation';
### LIS02A2: 13.5 Reagents
field 'reagents';
### LIS02A2: 13.6 Units of Measure
field 'units';
### LIS02A2: 13.7 Quality Control
field 'quality_control';
### LIS02A2: 13.8 Specimen Descriptor
field 'specimen_descriptor';
### LIS02A2: 13.9 Reserved Field
field 'reserved';
### LIS02A2: 13.10 Container
field 'container';
### LIS02A2: 13.11 Specimen ID
field 'specimen_id';
### LIS02A2: 13.12 Analyte
field 'analyte';
### LIS02A2: 13.13 Result
field 'result';
### LIS02A2: 13.14 Result Units
field 'result_units';
### LIS02A2: 13.15 Collection Date and Time
field 'collection_timestamp';
### LIS02A2: 13.16 Result Date and Time
field 'result_timestamp';
### LIS02A2: 13.17 Analytical Preprocessing Steps
field 'analytical_preprocessing_steps';
### LIS02A2: 13.18 Patient Diagnosis
field 'patient_diagnosis';
### LIS02A2: 13.19 Patient Birthdate
field 'patient_birthdate';
### LIS02A2: 13.20 Patient Sex
field 'patient_sex';
### LIS02A2: 13.21 Patient Race
field 'patient_race_ethnicity';

1;
