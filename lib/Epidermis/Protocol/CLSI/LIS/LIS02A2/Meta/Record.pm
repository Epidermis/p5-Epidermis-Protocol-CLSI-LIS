package Epidermis::Protocol::CLSI::LIS::LIS02A2::Meta::Record;
# ABSTRACT: Metaclass helpers for defining records

use strict;
use warnings;
use namespace::autoclean;

use Import::Into;
use Moo::_Utils qw(_install_tracked);

use MooX::ClassAttribute ();
use Scalar::Util qw(blessed);

use Epidermis::Protocol::CLSI::LIS::Types qw(RecordType RecordLevel);

our %RECORD_FIELD_STORE;

sub import {
	my $caller = caller;

	Moo::Role->apply_roles_to_package( $caller, __PACKAGE__ );

	MooX::ClassAttribute->import::into($caller);

	my $has = $caller->can( "has" ) or die "Moo not loaded in caller: $caller";

	$RECORD_FIELD_STORE{ $caller } = [];

	my $add_field = sub {
		my ($target, $name) = @_;
		push @{ $RECORD_FIELD_STORE{ $target } }, $name;
	};

	_install_tracked $caller => field => sub {
		my ($name, @args) = @_;

		$add_field->($caller, $name);
		$has->(
			$name,
			is => 'ro',
			@args,
		);
	};

	my $class_has  = $caller->can( "class_has" );

	_install_tracked $caller => record_type_id => sub {
		my ($record_char) = @_;
		my $name = 'type_id';

		$add_field->($caller, $name);
		$class_has->(
			$name,
			is => 'ro',
			isa => RecordType,
			default => sub { $record_char },
		);
	};

	_install_tracked $caller => record_level => sub {
		my ($record_level) = @_;
		my $name = '_level';

		# not a field
		$class_has->(
			$name,
			is => 'ro',
			isa => RecordLevel,
			default => sub { $record_level },
		);
	};
}

use Moo::Role;
use Package::Stash;
use List::Util qw(first);

sub _fields {
	my $package = blessed $_[0] ? ref $_[0] : $_[0];
	# quick-and-dirty inheritance
	my $up_package = exists $RECORD_FIELD_STORE{$package}
		? $package
		: first { /\A \QEpidermis::Protocol::CLSI::LIS::LIS02A2::Record::\E/x }
			@{ Package::Stash->new( $package )->get_symbol('@ISA') };
	return @{ $RECORD_FIELD_STORE{$up_package} };
}

has _number_of_decoded_fields => (
	is => 'ro',
);

1;
