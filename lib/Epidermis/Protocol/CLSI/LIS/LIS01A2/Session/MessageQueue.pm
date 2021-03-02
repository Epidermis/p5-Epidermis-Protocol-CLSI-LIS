package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue;
# ABSTRACT: Classes to help manage session message queue

use Modern::Perl;
use Types::Standard qw(InstanceOf);
use Epidermis::Protocol::CLSI::LIS::Types qw(FrameNumber);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Message;

use MooX::Struct -retain,
	MessageQueueItem => [
		message => [
			required => 1,
			isa => InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Message'],
		],
		future =>  [
			isa => InstanceOf['Future'],
			default => sub { Future->new->set_label('message queue item sent') },
		],
	];
our $MessageQueueItem = MessageQueueItem;

use MooX::Struct -retain,
	SendableMessage => [
		message_item => [ isa => MessageQueueItem->TYPE_TINY, required => 1 ],
		initial_fn => [ isa => FrameNumber, required => 1 ],
		message => [
			isa => InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Message'],
			lazy => 1, default => sub {
				my ($self) = @_;
				Epidermis::Protocol::CLSI::LIS::LIS01A2::Message->create_message(
					$self->message_item->message->message_data,
					{ start_frame_number => $self->initial_fn },
				);
			},
			handles => [ qw(
				frames
				number_of_frames
			) ],
		],

		_frame_index => [ default => sub { 0 } ],

		get_current_frame => sub {
			my ($self) = @_;
			$self->frames->[ $self->_frame_index ],
		},

		has_next_frame => sub {
			my ($self) = @_;
			$self->_frame_index + 1 < $self->number_of_frames;
		},

		next_frame => sub {
			my ($self) = @_;
			$self->_frame_index( $self->_frame_index + 1 );
		},
	];
our $SendableMessage = SendableMessage;


1;
