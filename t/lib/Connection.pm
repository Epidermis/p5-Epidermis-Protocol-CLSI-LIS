package # hide from PAUSE
	Connection;
# ABSTRACT: Helper for creating test connection

use Test::More;

use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';
use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat::Role::WithChild';
use aliased 'Epidermis::Lab::Test::Connection::Pipely';
use Moo::Role ();
use Try::Tiny;

my %CONNECTION_BUILDERS = (
		Socat => sub {
			Moo::Role->create_class_with_roles(Socat, WithChild)
				->new(
					$ENV{TEST_VERBOSE}
					? ( message_level => 0, socat_opts => [ qw(-x -v) ] )
					: ()
				);
		},
		Pipely => sub {
			Pipely->new;
		},
);

sub build_test_connection {
	my $test_conn;
	for my $name (qw(Socat Pipely)) {
		my $code = $CONNECTION_BUILDERS{$name};
		my $conn = try {
			note "Trying test connection $name";
			$code->();
		} catch {
			note "Error with $name test connection: $_";
		};
		if( $conn ) {
			$test_conn = $conn;
			last;
		} else {
			next;
		}
	}

	return $test_conn;
}

1;
