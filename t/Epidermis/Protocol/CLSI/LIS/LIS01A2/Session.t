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
		Socat->new( message_level => 0, socat_opts => [ qw(-x -v) ]  );
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
				})->else(sub {
					Future->done;
				});
		} until => sub {
			$count_in_idle == 1;
		};

		$loop->await_all( $r_f );
	};

	my @session_f;

	$socat->start;

	push @session_f, $loop->run_process(
		code => sub {
			my $cconn = Connection::Serial->new(
				device => $socat->pty0,
				mode => "9600,8,n,1",
			);
			$open_handle->($cconn);
			my $csess = Session->new( connection => $cconn, session_system => SYSTEM_COMPUTER );

			my $message_sent_f = $csess->send_message( $message );

			$run_sm->(IO::Async::Loop->new, $csess);
		},
	);

	push @session_f, $loop->run_process(
		code => sub {
			my $iconn = Connection::Serial->new(
				device => $socat->pty1,
				mode => "9600,8,n,1",
			);
			$open_handle->($iconn);
			my $isess = Session->new( connection => $iconn, session_system => SYSTEM_INSTRUMENT );

			$run_sm->(IO::Async::Loop->new, $isess);
		}
	);

	$loop->await_all( @session_f );

	pass;
}
};

done_testing;
