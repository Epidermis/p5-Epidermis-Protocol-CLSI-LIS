use Modern::Perl;
package Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageHeader;
# ABSTRACT: Message Header Record
### LIS02A2: 6     Message Header Record

use Moo;
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;
use Epidermis::Protocol::CLSI::LIS::Types qw(Separator);
use Types::Standard        qw(Str StrMatch ArrayRef);
use List::AllUtils qw(uniq);
use Epidermis::Protocol::CLSI::LIS::Constants qw(
	FIELD_SEP
	REPEAT_SEP
	COMPONENT_SEP
	ESCAPE_SEP

	ENCODING
);
use Encode qw(decode);

use failures qw( LIS02A2::Record::InvalidDelimiterSpec );

use MooX::Struct -retain,
	DelimiterSpec => [
		field_sep     => [ isa => Separator, default => sub { FIELD_SEP     } ],
		repeat_sep    => [ isa => Separator, default => sub { REPEAT_SEP    } ],
		component_sep => [ isa => Separator, default => sub { COMPONENT_SEP } ],
		escape_sep    => [ isa => Separator, default => sub { ESCAPE_SEP    } ],

		_check_valid_spec => sub {
			my ($self) = @_;
			failure::LIS02A2::Record::InvalidDelimiterSpec->throw(
				"Delimiter specification separators not unique"
			) unless @$self == uniq(@$self);
		},

		to_delimiter_definition => sub {
			my ($self) = @_;
			$self->_check_valid_spec;
			return join "", @$self, $self->field_sep;
		},

		_to_delimiter_for_join => sub {
			my ($self) = @_;
			$self->_check_valid_spec;
			return join "", @$self;
		},

		coerce => sub {
			my ($class, $data) = @_;

			my $return;
			if( $class->TYPE_TINY->check($data) ) {
				$return = $data;
			} elsif( (StrMatch[qr/^\A....\z/])->check($data) ) {
				$return = $class->new([ split //, $data ]);
			} elsif( (StrMatch[qr/^\A(.)...\1\z/])->check($data) ) {
				$return = $class->new([ split //, substr($data, 0, 4) ]);
			} elsif( (ArrayRef[Separator,4,4])->check($data) ) {
				$return = $class->new($data);
			}
			if( $return && $return->_check_valid_spec ) {
				return $return;
			}
			failure::LIS02A2::Record::InvalidDelimiterSpec->throw(
				"Could not coerce data for delimiter definition"
			);

		},

		TO_STRING => sub {
			my ($self) = @_;
			$self->to_delimiter_definition;
		},

		unescape => sub {
			my ($self, $field) = @_;

			my $escaped = $field;

			my @escapes = (
				{
					template => '&H&',
					description => 'start highlighting text',
				},
				{
					template => '&N&',
					description => 'normal text (end highlighting)',
				},
				{
					template => '&F&',
					description => 'imbedded field delimiter character',
					replace => $self->field_sep,
				},
				{
					template => '&S&',
					description => 'imbedded component field delimiter character',
					replace => $self->component_sep,
				},
				{
					template => '&R&',
					description => 'imbedded repeat field delimiter character',
					replace => $self->repeat_sep,
				},
				{
					template => '&E&',
					description => 'imbedded escape delimiter character',
					replace => $self->escape_sep,
				},
				{
					template => '&Xhhhh&',
					description => 'hexadecimal data',
				},
			);

			# remove highlighting
			$escaped =~ s/\Q@{[ $self->escape_sep ]}H@{[ $self->escape_sep ]}\E//g;
			$escaped =~ s/\Q@{[ $self->escape_sep ]}N@{[ $self->escape_sep ]}\E//g;

			$escaped =~ s/\Q@{[ $self->escape_sep ]}F@{[ $self->escape_sep ]}\E/@{[ $self->field_sep ]}/g;
			$escaped =~ s/\Q@{[ $self->escape_sep ]}S@{[ $self->escape_sep ]}\E/@{[ $self->component_sep ]}/g;
			$escaped =~ s/\Q@{[ $self->escape_sep ]}R@{[ $self->escape_sep ]}\E/@{[ $self->repeat_sep ]}/g;

			# escape + hex
			my $escape_sep_as_hex = unpack("H*", $self->escape_sep);
			my $double_escape = "@{[ $self->escape_sep ]}X$escape_sep_as_hex@{[ $self->escape_sep ]}";
			$escaped =~ s/\Q@{[ $self->escape_sep ]}E@{[ $self->escape_sep ]}\E/$double_escape/g;

			$escaped =~ s/\Q@{[ $self->escape_sep ]}X\E([0-9A-Fa-f]+)\Q@{[ $self->escape_sep ]}\E/decode( ENCODING, pack("H*",$1) )/g;

			$escaped;
		},
	];
our $DelimiterSpec = DelimiterSpec;

### LIS02A2: 6.1    Record Type ID
### 5.5.1 Message Header Record (H)
record_type_id 'H';

record_level 0;

### LIS02A2: 6.2    Delimiter Definition
field 'delimiter_definition', default => sub {
	DelimiterSpec->new;
}, isa => DelimiterSpec->TYPE_TINY|Str|ArrayRef, coerce => sub {
	DelimiterSpec->coerce($_[0]);
};

### LIS02A2: 6.3    Message Control ID
field 'message_control_id';

### LIS02A2: 6.4   Access Password
field 'access_password';

### LIS02A2: 6.5   Sender Name or ID
field 'sender_id';

### LIS02A2: 6.6   Sender Street Address
field 'sender_street_address';

### LIS02A2: 6.7   Reserved Field
field 'reserved';

### LIS02A2: 6.8   Sender Telephone Number
field 'sender_telephone';

### LIS02A2: 6.9   Characteristics of Sender
field 'sender_characteristics';

### LIS02A2: 6.10 Receiver ID
field 'receiver_id';

### LIS02A2: 6.11 Comment or Special Instructions
field 'comment';

### LIS02A2: 6.12 Processing ID
field 'processing_id';

### LIS02A2: 6.13 Version Number
field 'version', default => sub { 'LIS2-A2' };

### LIS02A2: 6.14 Date and Time of Message
field 'timestamp';

1;
