#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';

use Path::Tiny;
use File::Which;
use Child;

use IO::Termios;

use autodie;

use aliased 'Epidermis::Lab::Connection::Serial' => 'Connection::Serial';

sub create_serial_pty {
	die unless which('socat');
	my $tmpdir = Path::Tiny->tempdir;
	$tmpdir->mkpath;
	my $sender_pty = $tmpdir->child("sender-side");
	my $receiver_pty = $tmpdir->child("receiver-side");

	my @socat_pty_config = qw(pty raw echo=0);
	my @cmd = (
		qw(socat),
		#qw(-d -d -d -d),
		#qw(-d -d),
		join(",", @socat_pty_config, "link=$sender_pty"),
		join(",", @socat_pty_config, "link=$receiver_pty"),
	);
	my $child = Child->new(sub {
		my ($parent) = @_;
		#print "@cmd\n";
		exec( @cmd );
	});

	my $proc = $child->start;
	sleep 1;

	return +{
		sender_pty => $sender_pty,
		receiver_pty => $receiver_pty,
		proc => $proc,
		_pty_dir => $tmpdir,
	};
}

subtest "Test transmission" => sub {
	my $data = create_serial_pty;

	$data->{sender_pty_real} = $data->{sender_pty}->realpath;
	$data->{receiver_pty_real} = $data->{receiver_pty}->realpath;

	system( qw(ls -la), $data->{sender_pty});
	system( qw(ls -la), $data->{sender_pty_real});

	system( qw(ls -la), $data->{receiver_pty_real});
	system( qw(ls -la), $data->{receiver_pty});


	my $sender_conn = Connection::Serial->new(
		device => $data->{sender_pty},
		mode => "9600,8,n,1",
	);
	$sender_conn->open;

	my $receiver_conn = Connection::Serial->new(
		device => $data->{receiver_pty},
		mode => "9600,8,n,1",
	);
	$receiver_conn->open;

	#use DDP; p $sender_conn;

	pass;
};

END {
	kill 9, Child->all_proc_pids;
}

done_testing;
