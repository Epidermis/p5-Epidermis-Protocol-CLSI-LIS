package Epidermis::Lab::CLSI::LIS::LIS01A2::Message;
# ABSTRACT: LIS01A2 Message - a collection of related information on a single topic

use Moo;
use MooX::HandlesVia;

use Epidermis::Lab::CLSI::LIS::Types qw(FrameNumber);
use Types::Standard qw(ArrayRef InstanceOf);

use Epidermis::Lab::CLSI::LIS::Constants qw(LIS01A2_FIRST_FRAME_NUMBER);
use aliased 'Epidermis::Lab::CLSI::LIS::LIS01A2::Frame';

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
	isa => ArrayRef[InstanceOf['Epidermis::Lab::CLSI::LIS::LIS01A2::Frame']],
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

	# Check valid frame number sequence (modulo 8)
	my $next_frame_number = ($self->start_frame_number + $self->number_of_frames) % 8;
	LIS01A2::Message::InvalidFrameNumberSequence
		->throw("Frame number @{[ $frame->frame_number ]} is not sequential (expected: $next_frame_number)")
		if $frame->frame_number != $next_frame_number;

	# Check if last frame is end of message.
	failure::LIS01A2::Message::FrameAfterEndFrame->throw
		if( $self->is_complete );

	$self->_push_frame( $frame );
}

sub create_message {
	my ($class, $message_data) = @_;

	my $message = $class->new;

	my @frame_data = unpack( "(A@{[ FRAME_DATA_MAX_LENGTH ]})*", $message_data);
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
