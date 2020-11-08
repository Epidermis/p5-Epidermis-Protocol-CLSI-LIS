package Epidermis::Protocol::CLSI::LIS::LIS02A2::Message;
# ABSTRACT: LIS02A2 Message - collection of records from header to message terminator records

use Moo;
use MooX::HandlesVia;

use Types::Standard qw(ArrayRef ConsumerOf);

use Epidermis::Protocol::CLSI::LIS::Constants qw(RECORD_SEP);
use Epidermis::Protocol::CLSI::LIS::LIS02A2::Codec;
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageHeader';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS02A2::Record::MessageTerminator';

use failures qw(
	LIS02A2::Message::InvalidRecordNumberSequence
	LIS02A2::Message::InvalidRecordLevel
	LIS02A2::Message::RecordAfterEndRecord
);

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

has _records_stack => (
	is => 'ro',
	isa => ArrayRef[ConsumerOf['Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record']],
	default => sub { [] },
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

sub _check_record_increment_sequence {
	my ($self, $first, $second) = @_;
	$first->sequence->{data} + 1 == $second->sequence->{data};
}

sub _handle_stack {
	my ($self, $stack, $records, $record, $record_idx) = @_;
	if( @$stack == 0 ) {
		push @$stack, $record_idx;
		return;
	}

	if( $records->[ $stack->[-1] ]->type_id eq $record->type_id ) {
		my $last_idx = pop @$stack;
		if( ! $self->_check_record_increment_sequence($records->[ $last_idx ], $record) ) {
			failure::LIS02A2::Message::InvalidRecordNumberSequence->throw;
		}

		push @$stack, $record_idx;
		return;
	} else {
		if( ! defined $record->_level || $record->_level == @$stack ) {
			push @$stack, $record_idx;
			return;
		} elsif( $record->_level < @$stack ) {
			while( $record->_level < @$stack ) {
				pop @$stack;
			}
			$self->_handle_stack( $stack, $records, $record, $record_idx );
		} else {
			failure::LIS02A2::Message::InvalidRecordLevel->throw;
		}
	}
}

sub add_record {
	my ($self, $record) = @_;
	failure::LIS02A2::Message::RecordAfterEndRecord->throw
		if( $self->is_complete );

	if( $self->is_empty
		&& $record->type_id ne MessageHeader->type_id ) {
		failure::LIS02A2::Message::InvalidRecordLevel->throw;
	}

	# Check sequence and level
	$self->_handle_stack( $self->_records_stack, $self->records,
		$record, $self->number_of_records );
	$self->_push_record( $record );
}

sub as_outline {
	my ($self) = @_;

	my $records = $self->records;

	return $self->_as_outline_records( $records );
}

sub _as_outline_records {
	my ($self, $records) = @_;

	my $message_as_outline = "";
	my $previous_level = 0;

	for my $record (@$records) {
		my $level = ! defined $record->_level ? $previous_level : $record->_level;
		my $joined_records = $self->_record_to_text($record);
		$message_as_outline .=  ("  " x $level) .  $joined_records . "\n";
		$previous_level = $level;
	}

	return $message_as_outline;
}

sub _record_to_text {
	my ($self, $record) = @_;

	my @fields = $record->_fields;
	my $joined_records;
	my $last_field =
		$record->can('_number_of_decoded_fields')
			&& $record->_number_of_decoded_fields
		? $record->_number_of_decoded_fields - 1
		: $#fields;
	my $map_fields = sub {
		map {
			my $field = $record->$_ // '';
			ref $field ? $field->{text} : $field
		} @_;
	};
	if( $record->type_id eq 'H' ) {
		$joined_records = join(
			$self->codec->delimiter_spec->field_sep,
			$record->type_id . $self->codec->delimiter_spec->_to_delimiter_for_join,
			$map_fields->( @fields[2..$last_field] )
		);
	} else {
		$joined_records = join(
			$self->codec->delimiter_spec->field_sep,
			$map_fields->( @fields[0..$last_field] )
		);
	}

	return $joined_records;
}

sub _dump_record_stack_outline {
	my ($self) = @_;

	print $self->_as_outline_records( [
		map { $self->records->[$_] } @{ $self->_records_stack }
	]);
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

sub is_complete {
	my ($self) = @_;
	! $self->is_empty && $self->records->[-1]->type_id eq MessageTerminator->type_id;
}

1;
