package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Driver::Corruptible;
# ABSTRACT: Role to allow corrupting sent frame data

use Moo::Role;
use MooX::Should;
use Types::Standard qw(Bool);

has should_corrupt_frame_data => (
	is => 'rw',
	should => Bool,
	coerce => sub { 0 + !! $_[0] },
);

around _get_current_frame_data => sub {
	my ($orig, $self) = @_;
	my $frame_data = $self->$orig();

	if( $self->should_corrupt_frame_data ) {
		my $C2 = substr($frame_data, -3, 1);
		my $inc_C2 = sprintf( "%X", (hex($C2)+1)%16 );
		substr($frame_data, -3, 1) = $inc_C2;
	}

	$frame_data;
};

1;
