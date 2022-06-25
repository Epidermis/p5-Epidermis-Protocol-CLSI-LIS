package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::MessageQueue;
# ABSTRACT: Classes to help manage session message queue

use strict;
use warnings;
use namespace::autoclean;

use Types::Standard qw(InstanceOf Str);
use Epidermis::Protocol::CLSI::LIS::Types qw(FrameNumber);

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Message;
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame;

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
				Epidermis::Protocol::CLSI::LIS::LIS01A2::Message->create_message_from_frames(
					$self->message_item->message->frames,
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

use MooX::Struct -retain,
	ReceivableMessage => [
		initial_fn => [ isa => FrameNumber, required => 1 ],
		message => [
			isa => InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Message'],
			lazy => 1, default => sub {
				my ($self) = @_;
				Epidermis::Protocol::CLSI::LIS::LIS01A2::Message->new(
					start_frame_number => $self->initial_fn,
				);
			},
		],
		_current_frame_data => [
			is => 'rw',
			isa => Str,
		],
		_current_frame => [
			is => 'rw',
			isa => InstanceOf['Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame'],
		],

		set_current_frame_data => sub {
			my ($self, $frame_data ) = @_;

			$self->_current_frame_data( $frame_data );
		},

		process_current_frame_data => sub {
			my ($self) = @_;

			my $frame = Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame->parse_frame_data( $self->_current_frame_data );
			$self->message->add_frame( $frame );
		},
	];
our $ReceivableMessage = ReceivableMessage;

1;
