package Epidermis::Protocol::CLSI::LIS::LIS01A2::Message;
# ABSTRACT: LIS01A2 Message - a collection of related information on a single topic

use Moo;
use namespace::autoclean;
use MooX::HandlesVia;

use Epidermis::Protocol::CLSI::LIS::Types qw(FrameNumber);
use Types::Standard qw(ArrayRef InstanceOf);

use Epidermis::Protocol::CLSI::LIS::Constants qw(LIS01A2_FIRST_FRAME_NUMBER);
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame';

use constant FRAME_DATA_MAX_LENGTH => 240;

use failures qw(
	LIS01A2::Message::InvalidFrameNumberSequence
	LIS01A2::Message::FrameAfterEndFrame
);

has start_frame_number => (
	is => 'ro',
	required => 0,
	isa => FrameNumber,
	default => sub { LIS01A2_FIRST_FRAME_NUMBER },
);

has frames => (
	is => 'ro',
	init_arg => undef,
	isa => ArrayRef[InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame']],
	default => sub { [] },
	handles_via => 'Array',
	handles => {
		is_empty => 'is_empty',
		number_of_frames => 'count',
		_push_frame => 'push',
	},
);

sub add_frame {
	my ($self, $frame) = @_;

	# Check valid frame number sequence
	my $next_frame_number = $self->is_empty
		? $self->start_frame_number
		: $self->frames->[-1]->next_frame_number;
	failure::LIS01A2::Message::InvalidFrameNumberSequence
		->throw({
			msg => "Frame number is not sequential",
			payload => {
				got => $frame->frame_number,
				expected => $next_frame_number,
			},
		}) if $frame->frame_number != $next_frame_number;

	# Check if last frame is end of message.
	failure::LIS01A2::Message::FrameAfterEndFrame->throw
		if( $self->is_complete );

	$self->_push_frame( $frame );
}

sub split_message_data_into_frame_data {
	my ($self, $message_data) = @_;

	my @frame_data = unpack( "(A@{[ FRAME_DATA_MAX_LENGTH ]})*", $message_data);

	\@frame_data;
}

sub create_message {
	my ($class, $message_data, $message_args ) = @_;

	$message_args //= {};

	my $message = $class->new( $message_args );

	my @frame_data = @{ $message->split_message_data_into_frame_data( $message_data ) };
	my $frame_number = $message->start_frame_number;
	while( @frame_data ) {
		my $content = shift @frame_data;
		$message->add_frame( my $frame = Frame->new(
			frame_number => $frame_number,
			content => $content,
			type => ( @frame_data ? 'intermediate' : 'end' ),
		));

		$frame_number = $frame->next_frame_number;
	}

	return $message;
}

sub message_data {
	my ($self) = @_;
	join "", map { $_->content } @{ $self->frames };
}

sub is_complete {
	my ($self) = @_;
	! $self->is_empty && $self->frames->[-1]->is_end;
}

1;
