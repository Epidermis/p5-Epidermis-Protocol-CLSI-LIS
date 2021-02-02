#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine';
use IPC::Run qw(run);

sub render_plantuml_to_text {
	my ($plantuml) = @_;

	my $txt_out;
	run [ qw(plantuml -tutxt -pipe) ], \$plantuml, \$txt_out;
	return $txt_out;
}

sub render_plantuml_to_png {
	my ($plantuml) = @_;

	my $png_out;
	run [ qw(plantuml -tpng -pipe) ], \$plantuml, \$png_out;
	return $png_out;
}

sub show_plantuml {
	my ($sm) = @_;

	my $plantuml = $sm->to_plantuml;
	print $plantuml;

	my $txt_out = render_plantuml_to_text($plantuml);
	print $txt_out;

	if( 0 ) {
		my $png_out = render_plantuml_to_png($plantuml);
		run [ qw(display -) ], \$png_out;
	}
}

subtest "Create state machine" => sub {
	my $sm = StateMachine->new;

	pass;
};

done_testing;
