package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::TestMessages;
# ABSTRACT: Messages for testing

use Mu;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame' => 'LIS01A2::Frame';
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Frame::Constants
	qw(:frame_type);

use Epidermis::Protocol::CLSI::LIS::Constants qw(
	LIS01A2_FIRST_FRAME_NUMBER
);

lazy single_frame => sub {
	my $message = LIS01A2::Message->create_message( 'Hello world' );
};

sub multiple_frames {
	my ($self, $count) = @_;
	$count = 2 unless $count;

	my @frames;
	for my $frame_id (1..$count) {
		my $frame = LIS01A2::Frame->new(
			content => "frame $frame_id",
			type => $frame_id == $count
				? FRAME_TYPE_END
				: FRAME_TYPE_INTERMEDIATE ,
		);
		push @frames, $frame;
	}

	my $message = LIS01A2::Message
		->create_message_from_frames(\@frames);

	$message;
}

1;
