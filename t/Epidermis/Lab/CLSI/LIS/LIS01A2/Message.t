#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use aliased 'Epidermis::Lab::CLSI::LIS::LIS01A2::Message';

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

done_testing;
