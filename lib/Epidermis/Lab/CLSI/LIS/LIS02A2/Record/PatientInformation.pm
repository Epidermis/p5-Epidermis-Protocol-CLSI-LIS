use Modern::Perl;
package Epidermis::Lab::CLSI::LIS::LIS02A2::Record::PatientInformation;
# ABSTRACT: Patient Information Record
### LIS02A2: 7     Patient Information Record

use Moo;
use Epidermis::Lab::CLSI::LIS::LIS02A2::Meta::Record;

### LIS02A2: 7.1    Record Type
### 5.5.2 Patient Identifying Record (P)
record_type_id 'P';

### LIS02A2: 7.2    Sequence Number
field 'sequence';
### LIS02A2: 7.3    Practice-Assigned Patient ID
field 'practice_id';
### LIS02A2: 7.4    Laboratory-Assigned Patient ID
field 'lab_id';
### LIS02A2: 7.5    Patient ID Number 3
field 'id';
### LIS02A2: 7.6    Patient Name
field 'name';
### LIS02A2: 7.7    Mother’s Maiden Name
field 'maiden_name';
### LIS02A2: 7.8    Birthdate
field 'birthdate';
### LIS02A2: 7.9   Patient Sex
field 'sex';
### LIS02A2: 7.10 Patient Race-Ethnic Origin
field 'race_ethnicity';
### LIS02A2: 7.11 Patient Address
field 'address';
### LIS02A2: 7.12 Reserved Field
field 'reserved';
### LIS02A2: 7.13 Patient Telephone Number
field 'telephone';
### LIS02A2: 7.14 Attending Physician ID
field 'physician_id';
### LIS02A2: 7.15 Special Field 1
field 'special_1';
### LIS02A2: 7.16 Special Field 2
field 'special_2';
### LIS02A2: 7.17 Patient Height
field 'height';
### LIS02A2: 7.18 Patient Weight
field 'weight';
### LIS02A2: 7.19 Patient’s Known or Suspected Diagnosis
field 'diagnosis';
### LIS02A2: 7.20 Patient Active Medications
field 'medication';
### LIS02A2: 7.21 Patient’s Diet
field 'diet';
### LIS02A2: 7.22 Practice Field Number 1
field 'practice_field_1';
### LIS02A2: 7.23 Practice Field Number 2
field 'practice_field_2';
### LIS02A2: 7.24 Admission and Discharge Dates
field 'admission_discharge_dates';
### LIS02A2: 7.25 Admission Status
field 'admission_status';
### LIS02A2: 7.26 Location
field 'location';
### LIS02A2: 7.27 Nature of Alternative Diagnostic Code and Classifiers
field 'alt_diagnostic_code_nature';
### LIS02A2: 7.28 Alternative Diagnostic Code and Classification
field 'alt_diagnostic_code';
### LIS02A2: 7.29 Patient Religion
field 'religion';
### LIS02A2: 7.30 Marital Status
field 'marital_status';
### LIS02A2: 7.31 Isolation Status
field 'isolation_status';
### LIS02A2: 7.32 Language
field 'language';
### LIS02A2: 7.33 Hospital Service
field 'hospital_service';
### LIS02A2: 7.34 Hospital Institution
field 'hospital_institution';
### LIS02A2: 7.35 Dosage Category
field 'dosage_category';

1;
__END__
