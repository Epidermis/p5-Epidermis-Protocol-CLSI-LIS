package Epidermis::Protocol::CLSI::LIS::LIS02A2::Message;
# ABSTRACT: LIS02A2 Message - TODO

use Moo;
use MooX::HandlesVia;

use Types::Standard qw(ArrayRef ConsumerOf);

has _codec => (
	is => 'rw',
);

has records => (
	is => 'ro',
	init_arg => undef,
	isa => ArrayRef[ConsumerOf['Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record']],
	default => sub { [] },
	handles_via => 'Array',
	handles => {
		is_empty => 'is_empty',
		number_of_records => 'count',
		_push_record => 'push',
	},
);

sub add_record_text {
	my ($self, $record_text) = @_;
	if( $self->is_empty ) {
		my $codec = Epidermis::Protocol::CLSI::LIS::LIS02A2::Codec->new_from_message_header_data(
			$record_text,
		);
		$self->_codec( $codec );
	}

	my $data = $self->_codec->decode_record_data($record_text);
	# TODO check sequence and level
	$self->_push_record( $data );
}

sub as_outline {
	my ($self) = @_;

	my $records = $self->records;

	my $message_as_outline = "";
	my $previous_level = 0;

	for my $record (@$records) {
		my $level = ! defined $record->_level ? $previous_level : $record->_level;
		my @fields = $record->_fields;
		my $joined_records;
		my $last_field =
			$record->can('_number_of_decoded_fields')
				&& $record->_number_of_decoded_fields
			? $record->_number_of_decoded_fields - 1
			: $#fields;
		if( $record->type_id eq 'H' ) {
			$joined_records = join(
				$self->_codec->delimiter_spec->field_sep,
				$record->type_id . $self->_codec->delimiter_spec->_to_delimiter_for_join,
				map {
					my $field = $record->$_ // '';
					ref $field ? $field->{text} : $field
				} @fields[2..$last_field]
			);
		} else {
			$joined_records = join(
				$self->_codec->delimiter_spec->field_sep,
				map {
					my $field = $record->$_ // '';
					ref $field ? $field->{text} : $field
				} @fields[0..$last_field]
			);
		}
		$message_as_outline .=  ("  " x $level) .  $joined_records . "\n";
		$previous_level = $level;
	}

	return $message_as_outline;
}

1;
