package Epidermis::Protocol::CLSI::LIS::LIS02A2::Codec;
# ABSTRACT: Encoder-decoder for LIS02A2

use Moo;
use namespace::autoclean;
use Epidermis::Protocol::CLSI::LIS::Constants qw(
	ENCODING
);

use Epidermis::Protocol::CLSI::LIS::Types qw(RecordType);
use Types::Standard qw(Map ClassName Str);

use Epidermis::Protocol::CLSI::LIS::LIS02A2;
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageHeader';

use failures qw(
	LIS02A2::Codec::InvalidMessageHeader
	LIS02A2::Codec::UnknownRecordTypeID
	LIS02A2::Codec::TooManyFieldsForRecord
);

has encoding => (
	is => 'ro',
	isa => Str,
	default => sub { ENCODING },
);

has delimiter_spec => (
	is => 'ro',
	default => sub {
		$Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageHeader::DelimiterSpec->new,
	},
);

has type_id_record_map => (
	is => 'ro',
	isa => Map[RecordType, ClassName],
	default => sub {
		+{ map { $_->type_id =>  $_ }
		@Epidermis::Protocol::CLSI::LIS::LIS02A2::BASE_RECORD_TYPE_PACKAGES }
	},
);

sub new_from_message_header_data {
	my ($class,  $message_header_data, %options) = @_;
	if( substr($message_header_data,0,1) ne MessageHeader->type_id ) {
		failure::LIS02A2::Codec::InvalidMessageHeader->throw(
			"Data does not start with expected type ID: @{[ MessageHeader->type_id ]}"
		);
	}

	my $DelimiterSpec = $Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageHeader::DelimiterSpec->new;

	my $spec = $DelimiterSpec->coerce( substr($message_header_data, 1, 5) );

	$class->new(
		delimiter_spec => $spec,
		%options,
	);
}

sub decode_record_data {
	my ($self, $record_data) = @_;
	my $DelimiterSpec = $self->delimiter_spec;

	my $record = [ split /\Q@{[ $DelimiterSpec->field_sep ]}\E/, $record_data, -1 ];

	my $number_of_decoded_fields = @$record;

	my $type_id = shift @$record;
	unless ( exists $self->type_id_record_map->{$type_id} ) {
		failure::LIS02A2::Codec::UnknownRecordTypeID->throw(
			"Type ID $type_id not registered"
		);
	}

	my @field_names = $self->type_id_record_map->{$type_id}->_fields;
	shift @field_names if $field_names[0] eq 'type_id'; # remove type_id

	unless( @$record <= @field_names ) {
		failure::LIS02A2::Codec::TooManyFieldsForRecord->throw
	}

	# 5.4.7 Delimiters for Null Values
	# Delimiters are not included for trailing null fields
	my %field_to_data = map {
		$record->[$_]
		? ( $field_names[$_] => $record->[$_] )
		: ()
	} 0..@$record - 1;

	if( $type_id eq MessageHeader->type_id ) {
		# This is already parsed by the codec. Will add back later.
		delete $field_to_data{delimiter_definition};
	}

	for my $key (keys %field_to_data) {
		my $field_value = $field_to_data{$key};

		my $repeats = bless
			[ split /\Q@{[ $DelimiterSpec->repeat_sep ]}\E/, $field_value ],
			'RepeatFields';
		for my $repeat (@$repeats) {
			my $components = bless
				[ split /\Q@{[ $DelimiterSpec->component_sep ]}\E/, $repeat ],
				'ComponentFields';
			for my $component (@$components) {
				my $unescaped = $DelimiterSpec->unescape( $component );
				$component = $unescaped;
			}
			$repeat = @$components == 1 ? $components->[0] : $components;
		}

		my $field_data = @$repeats == 1 ? $repeats->[0] : $repeats ;

		$field_to_data{$key} = bless {
			data => $field_data,
			text => $field_value
		}, 'Field';
	}

	if( $type_id eq MessageHeader->type_id ) {
		# This is already parsed by the codec. Adding back.
		$field_to_data{delimiter_definition} = $DelimiterSpec;
	}

	my $record_object = $self->type_id_record_map->{$type_id}->new(
		%field_to_data,
		_number_of_decoded_fields => $number_of_decoded_fields,
	);

	return $record_object;
}

1;
