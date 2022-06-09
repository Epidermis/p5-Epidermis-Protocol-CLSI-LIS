#!/usr/bin/env perl

use Test2::V0;
plan tests => 2;

use lib 't/lib';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame';

subtest "Create message" => sub {
	subtest "Zero frames message" => sub {
		ok Message->new->is_empty, 'Message starts empty';
	};

	subtest "One frame message" => sub {
		my $message_data = 'a' x Message->FRAME_DATA_MAX_LENGTH;
		my $message = Message->create_message( $message_data );
		is $message->number_of_frames, 1, 'Max length message fits in 1 frame';
		ok $message->frames->[-1]->is_end, 'Last frame is end frame';

		is $message->message_data, $message_data, 'Message data round-trip';
	};

	subtest "Two frames message" => sub {
		my $message_data = 'a' x (Message->FRAME_DATA_MAX_LENGTH + 1);
		my $message = Message->create_message( $message_data );
		is $message->number_of_frames, 2, 'Message needs 2 frames';
		ok $message->frames->[0]->is_intermediate, 'First frame is intermediate frame';
		ok $message->frames->[-1]->is_end, 'Last frame is end frame';

		is $message->message_data, $message_data, 'Message data round-trip';
	};
};

subtest "Create message from from frames" => sub {
	subtest "Correct message" => sub {
		my $message = Message->new;
		ok lives {
			$message->add_frame( Frame->new( frame_number => 1, content => 'a', type => 'intermediate' ) );
			$message->add_frame( Frame->new( frame_number => 2, content => 'b', type => 'intermediate' ) );
			$message->add_frame( Frame->new( frame_number => 3, content => 'c', type => 'end' ) );
		}, 'Added 3 sequential frames' or note $@;

		is $message->message_data, 'abc', 'Expected message data';
	};

	subtest "Correct message (with different starting frame number)" => sub {
		my $message = Message->new( start_frame_number => 6 );
		ok lives {
			$message->add_frame( Frame->new( frame_number => 6, content => 'a', type => 'intermediate' ) );
			$message->add_frame( Frame->new( frame_number => 7, content => 'b', type => 'intermediate' ) );
			$message->add_frame( Frame->new( frame_number => 0, content => 'c', type => 'end' ) );
		}, 'Added 3 sequential frames' or note $@;

		is $message->message_data, 'abc', 'Expected message data';
	};

	subtest "Invalid frame number sequence" => sub {
		my $message = Message->new;
		like dies {
			$message->add_frame( Frame->new( frame_number => 7, content => 'a', type => 'end' ) );
		}, qr/InvalidFrameNumberSequence/;
	};

	subtest "Adding after end frame" => sub {
		my $message = Message->new;
		$message->add_frame( Frame->new( frame_number => 1, content => 'a', type => 'intermediate' ) );
		$message->add_frame( Frame->new( frame_number => 2, content => 'b', type => 'end' ) );
		like dies {
			$message->add_frame( Frame->new( frame_number => 3, content => 'c', type => 'end' ) );
		}, qr/FrameAfterEndFrame/;
	};
};

done_testing;
