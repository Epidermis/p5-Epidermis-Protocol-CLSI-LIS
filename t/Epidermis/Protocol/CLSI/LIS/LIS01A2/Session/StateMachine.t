#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine';
use IPC::Run qw(run);

subtest "Create state machine" => sub {
	my $sm = StateMachine->new;
	use DDP; p $sm;
	my $map = $sm->_state_map;

	my $plantuml;
	$plantuml .= "\@startuml\n\n";
	$plantuml .= "[*] --> n_idle\n";
	for my $from ( sort keys %$map ) {
		for my $to ( sort keys %{ $map->{$from} } ) {
			my $event = $map->{$from}{$to}{event};
			my $action = $map->{$from}{$to}{action};
			my $action_italics = join '\n', map { "//$_//" } @$action;
			$plantuml .= "$from --> $to : $event\\n$action_italics";
			$plantuml .= "\n";
		}
	}

	$plantuml .= "\n";
	$plantuml .= "\@enduml\n";

	print $plantuml;
	my $txt_out;
	run [ qw(plantuml -tutxt -pipe) ], \$plantuml, \$txt_out;
	print $txt_out;

	if( 0 ) {
	my $png_out;
	run [ qw(plantuml -tpng -pipe) ], \$plantuml, \$png_out;
	run [ qw(display -) ], \$png_out;
	}

	pass;
};

done_testing;
