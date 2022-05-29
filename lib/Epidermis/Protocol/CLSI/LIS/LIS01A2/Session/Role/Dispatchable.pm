package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable;
# ABSTRACT: Dispatch tables for session

use Mu::Role;
use namespace::autoclean;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_event :enum_action);

lazy _action_dispatch_table => sub {
	my ($self) = @_;
	my $dispatch;
	for my $action (@ENUM_ACTION) {
		my $action_method = "do_${action}";
		if( my $code = $self->can( $action_method ) ) {
			$dispatch->{ $action } = $code;
		} else {
			warn "No method $action_method for action $action";
		}
	}
	$dispatch;
};

lazy _event_dispatch_table => sub {
	my ($self) = @_;
	my $dispatch;
	for my $event (@ENUM_EVENT) {
		my $event_method = "event_on_${event}";
		if( my $code = $self->can( $event_method ) ) {
			$dispatch->{ $event } = $code;
		} else {
			warn "No method $event_method for event $event";
		}
	}
	$dispatch;
};

1;
