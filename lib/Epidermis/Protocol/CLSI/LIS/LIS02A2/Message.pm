package Epidermis::Protocol::CLSI::LIS::LIS02A2::Message;
# ABSTRACT: LIS02A2 Message - collection of records from header to message terminator records

use Moo;
use MooX::HandlesVia;

use Types::Standard qw(ArrayRef ConsumerOf);

use Epidermis::Protocol::CLSI::LIS::Constants qw(RECORD_SEP);

has codec => (
	is => 'rw',
	predicate => 1,
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

sub _set_codec_from_record_text {
	my ($self, $record_text) = @_;
	die "Codec already set\n" if $self->has_codec;
	my $codec = Epidermis::Protocol::CLSI::LIS::LIS02A2::Codec->new_from_message_header_data(
		$record_text,
	);
	$self->codec( $codec );
}

sub add_record_text {
	my ($self, $record_text) = @_;
	if( $self->is_empty ) {
		$self->_set_codec_from_record_text( $record_text );
	}

	my $data = $self->codec->decode_record_data($record_text);
	$self->add_record( $data );
}

sub add_record {
	my ($self, $record) = @_;
	# TODO check sequence and level
	$self->_push_record( $record );
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
				$self->codec->delimiter_spec->field_sep,
				$record->type_id . $self->codec->delimiter_spec->_to_delimiter_for_join,
				map {
					my $field = $record->$_ // '';
					ref $field ? $field->{text} : $field
				} @fields[2..$last_field]
			);
		} else {
			$joined_records = join(
				$self->codec->delimiter_spec->field_sep,
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

sub create_message {
	my ($class, $message_text) = @_;

	my @records = split /\Q@{[ RECORD_SEP ]}\E/, $message_text;

	my $message = $class->new;

	for my $record (@records) {
		$message->add_record_text($record);
	}

	$message;
}

1;
