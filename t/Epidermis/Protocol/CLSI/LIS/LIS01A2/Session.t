#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use StandardData;

use IO::Async::Loop;
use Future::IO::Impl::IOAsync;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

use aliased 'Epidermis::Lab::Connection::Serial' => 'Connection::Serial';

use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';
use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat::Role::WithChild';
use Moo::Role ();
use Try::Tiny;

use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();
Log::Any::Adapter->set('Screen', min_level => 'trace' );

use Log::Any qw($log);

use Future::Utils qw(fmap_void repeat);
use Data::Dumper;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_system :enum_state);

use boolean;

subtest "Test session" => sub {
SKIP: {
	my $socat = try {
		Moo::Role->create_class_with_roles(Socat, WithChild)
			->new( message_level => 0, socat_opts => [ qw(-x -v) ]  );
	} catch {
		skip $_;
	};

	my $message = LIS01A2::Message->create_message('Hello, world!');

	my $loop = IO::Async::Loop->new;

	my $open_handle = sub {
		my ($conn) = @_;
		$conn->open;
		#$conn->handle->blocking(0);
		#$conn->handle->cfmakeraw;
		#$conn->handle->setflag_echo(0);
		#$conn->handle->setflag_clocal( 1 );
	};

	my $run_sm = sub {
		my $loop = shift;
		my $session = shift;
		$log->trace("===> $session");

		my $count_in_idle = 0;
		my $r_f = repeat {
			my $f = $session->step
				->on_fail(sub {
					my ($f1) = @_;
					$log->trace( "Failed: " . Dumper($f1) );
				})->followed_by(sub {
					my ($f1) = @_;
					$log->trace("Then: $session");
					$count_in_idle++ if $session->session_state eq STATE_N_IDLE;
					$log->trace(" Idle count $session: $count_in_idle" );
					Future->done;
				})->else(sub {
					Future->done;
				});
		} until => sub {
			$count_in_idle == 1;
		};

		$loop->await_all( $r_f );
	};

	my $setup_system = sub {
		my ( $device, $system, $message ) = @_;

		my $session = Session->new(
			connection => Connection::Serial->new(
				device => $device,
				mode => "9600,8,n,1",
			),
			session_system => $system,
		);

		$open_handle->( $session->connection );

		my $message_sent_f;
		if( $message ) {
			$session->send_message( $message );
		}

		$run_sm->( IO::Async::Loop->new, $session );
	},

	my @session_f;

	$socat->start_via_child;

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $socat->pty0, SYSTEM_COMPUTER, $message );
		}
	);

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $socat->pty1, SYSTEM_INSTRUMENT, undef );
		}
	);

	$loop->await_all( @session_f );

	pass;
}
};

done_testing;
