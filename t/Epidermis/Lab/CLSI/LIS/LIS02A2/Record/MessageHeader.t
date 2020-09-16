#!/usr/bin/env perl

use Test::Most tests => 1;

use aliased 'Epidermis::Lab::CLSI::LIS::LIS02A2::Record::MessageHeader';

use lib 't/lib';

subtest "Create message header" => sub {
	is MessageHeader->new->type_id, 'H', 'Record type ID';

	subtest "Default delimiters" => sub {
		my $header = MessageHeader->new;
		is $header->delimiter_definition, q{|\^&|}, 'Got default delimiters';
		is $header->delimiter_definition->escape_sep, '&',
			'Access individual elements of delimiter spec';
	};

	subtest "Custom delimiters" => sub {
		{
			my $header = MessageHeader->new( delimiter_definition => 'Zbcd' );
			is $header->delimiter_definition, q{ZbcdZ}, 'Str of 4 characters';
		}

		{
			my $header = MessageHeader->new( delimiter_definition => 'ZbcdZ' );
			is $header->delimiter_definition, q{ZbcdZ}, 'Str of 5 characters';
		}

		{
			my $header = MessageHeader->new( delimiter_definition => [ qw(Z b c d) ] );
			is $header->delimiter_definition, q{ZbcdZ}, 'ArrayRef of 4 characters';
		}

		throws_ok {
			my $header = MessageHeader->new( delimiter_definition => [ qw(Z b c b) ] );
		} qr/InvalidDelimiterSpec.*unique/, 'Separators not unique';

		throws_ok {
			my $header = MessageHeader->new( delimiter_definition => [ qw(Z b c d e) ] );
		} qr/InvalidDelimiterSpec/, 'ArrayRef too long';

		throws_ok {
			my $header = MessageHeader->new( delimiter_definition => [ qw(Zed b c d) ] );
		} qr/InvalidDelimiterSpec/, 'Separator not a single character';
	};
};

done_testing;
