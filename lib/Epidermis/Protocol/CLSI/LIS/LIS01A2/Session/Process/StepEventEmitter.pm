package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEventEmitter;
# ABSTRACT: Role to emit session events

use Mu::Role;
use namespace::autoclean;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Process::StepEvent';

with qw(Beam::Emitter);

around process_step => sub {
	my ($orig, $self, @args) = @_;
	$self->$orig(@args)
		->transform( done => sub {
			my ($result) = @_;
			$self->emit( 'step',
				class => StepEvent,
				state_transition => $result,
			);
			return $result;
		});
};

1;
