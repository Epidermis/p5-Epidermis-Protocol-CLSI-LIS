#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use StandardData;

use IO::Async::Loop;
use Future::IO::Impl::IOAsync;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Message' => 'LIS01A2::Message';

use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat';
use aliased 'Epidermis::Lab::Test::Connection::Serial::Socat::Role::WithChild';
use Moo::Role ();
use Try::Tiny;

use Log::Any::Adapter;
use Log::Any::Adapter::Screen ();

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
			->new(
				$ENV{TEST_VERBOSE}
				? ( message_level => 0, socat_opts => [ qw(-x -v) ] )
				: ()
			);
	} catch {
		skip $_;
	};

	Log::Any::Adapter->set( {
		lexically => \my $lex,
		category => qr/^main$|^Epidermis::Protocol::CLSI::LIS::LIS01A2::Session/ },
		'Screen', min_level => 'trace', formatter => sub { $_[1] =~ s/^/  # LOG: /mgr } ) if $ENV{TEST_VERBOSE};

	my $message = LIS01A2::Message->create_message('Hello, world!');

	my $loop = IO::Async::Loop->new;

	my $open_handle = sub {
		my ($conn) = @_;
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
		my $step_count = 0;
		my $r_f = repeat {
			my $f = $session->step
				->on_fail(sub {
					my ($f1) = @_;
					$log->trace( "Failed: " . Dumper($f1) );
				})->followed_by(sub {
					my ($f1) = @_;
					$count_in_idle++ if $session->session_state eq STATE_N_IDLE;
					++$step_count;
					$log->tracef(
						"[%s] Step %d (I:%d): %s :: %s",
						$session->name,
						$step_count,
						$count_in_idle,
						$f1->get,
						$session,
					);
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
		my ( $connection, $system, $message ) = @_;

		my $session = Session->new(
			connection => $connection,
			session_system => $system,
			name => substr($system, 0, 1),
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
			$setup_system->( $socat->connection0, SYSTEM_COMPUTER, $message );
		}
	);

	push @session_f, $loop->run_process(
		code => sub {
			$setup_system->( $socat->connection1, SYSTEM_INSTRUMENT, undef );
		}
	);

	$loop->await_all( @session_f );

	pass;
}
};

done_testing;
