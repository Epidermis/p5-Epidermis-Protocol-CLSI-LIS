#!/usr/bin/env perl

use Test2::V0;
plan tests => 2;

use lib 't/lib';
use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::StateMachine';
use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_state :enum_event :enum_action);
use IPC::Run qw(run);
use File::Which;
use List::AllUtils;

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
	my ($sm, %opt) = @_;

	if(!%opt) {
		$opt{text} = 1;
	}

	my $plantuml = $sm->to_plantuml;
	note "PlantUML:\n\n", $plantuml;

	return unless which('plantuml');

	if( $opt{text} ) {
		my $txt_out = render_plantuml_to_text($plantuml);
		print $txt_out;
	}

	if( $opt{png} && which('display') ) {
		my $png_out = render_plantuml_to_png($plantuml);
		run [ qw(display -) ], \$png_out;
	}
}

subtest "Create state machine" => sub {
	my $sm = StateMachine->new;
	ok $sm;
	show_plantuml($sm, text => 0, png => 0 );
};

subtest "Check state machine transitions: actions" => sub {
	my $sm = StateMachine->new;

	my $actions_for_to = sub {
		my ($to) = @_;
		my @actions;

		my $map = $sm->_state_map;
		for my $from (keys %$map ) {
			next unless exists $map->{$from}{$to};
			push @actions, $map->{$from}{$to}{action};
		}
		\@actions;
	};

	my $all_to_state_have_action = sub {
		my ($to_state, $action) = @_;

		my $all_actions_for_to = $actions_for_to->( $to_state );

		return List::AllUtils::all {
			my $action_list = $_;
			List::AllUtils::any { $_ eq $action } @$action_list
		} @$all_actions_for_to
	};

	subtest "Device = neutral" => sub {
		ok $all_to_state_have_action->( STATE_N_IDLE, ACTION_SET_DEVICE_TO_NEUTRAL );
	};

	subtest "Device = sender" => sub {
		ok $all_to_state_have_action->( STATE_S_ESTABLISH_SEND_DATA, ACTION_SET_DEVICE_TO_SENDER );
	};

	subtest "Device = receiver" => sub {
		ok $all_to_state_have_action->( STATE_R_AWAKE, ACTION_SET_DEVICE_TO_RECEIVER );
	};

	subtest "Setup new frame" => sub {
		ok $all_to_state_have_action->( STATE_S_TRANSFER_SETUP_NEXT_FRAME, ACTION_SETUP_NEXT_FRAME );
	};
};

done_testing;
