package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Role::Dispatchable;
# ABSTRACT: Dispatch tables for session

use Mu::Role;

use Package::Stash;

use Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Constants
	qw(:enum_event :enum_action);

lazy _action_dispatch_table => sub {
	my ($self) = @_;
	my $dispatch;
	my $stash = Package::Stash->new( ref $self );
	for my $action (@ENUM_ACTION) {
		my $action_symbol = "&do_${action}";
		if( my $code = $stash->get_symbol( $action_symbol ) ) {
			$dispatch->{ $action } = $code;
		} else {
			warn "No method $action_symbol for action $action";
		}
	}
	$dispatch;
};

lazy _event_dispatch_table => sub {
	my ($self) = @_;
	my $dispatch;
	my $stash = Package::Stash->new( ref $self );
	for my $event (@ENUM_EVENT) {
		my $event_symbol = "&event_on_${event}";
		if( my $code = $stash->get_symbol( $event_symbol ) ) {
			$dispatch->{ $event } = $code;
		} else {
			warn "No method $event_symbol for event $event";
		}
	}
	$dispatch;
};

1;
