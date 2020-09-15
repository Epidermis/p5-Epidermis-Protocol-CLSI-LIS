package Epidermis::Lab::CLSI::LIS::LIS01A2::Connection::Serial;
# ABSTRACT: A connection for serial binary data exchange

use Moo;

use Fcntl ();
use IO::Termios ();
use IO::Stty ();

has device => (
	is => 'ro',
	required => 1,
);

has mode => (
	is => 'ro',
	predicate => 1,
);

has _handle => (
	is => 'rw',
);

sub is_open {
	my ($self) = @_;
	defined $self->_handle;
}

sub open {
	my ($self) = @_;

	sysopen my $fh, $self->device, Fcntl::O_RDWR
		or die "sysopen failed on @{[ $self->device ]}: $!";
	my $handle = IO::Termios->new( $fh )
		or die "using IO::Termios failed on @{[ $self->device ]}: $!";
	$self->_handle( $handle );
	if( $self->has_mode ) {
		$self->_handle->set_mode( $self->mode );
	}
}

1;
