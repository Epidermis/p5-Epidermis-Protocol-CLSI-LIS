#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use StandardData;

use aliased 'Epidermis::Protocol::CLSI::LIS::LIS02A2::Message';

use XXX;
use List::AllUtils qw(first);

my $MessageWTree = Moo::Role->create_class_with_roles(
	Message,
	qw(Epidermis::Protocol::CLSI::LIS::LIS02A2::Message::Role::TreeDAG) );

subtest "Test message creation from text" => sub {
	my $text = StandardData->lis02a2_standard_data_text_to_message_text(
		( first { $_->{id} eq 'fig7' } @{ StandardData->lis02a2_standard_data } )
			->{text}
	);

	subtest "Create message" => sub {
		my $lis_msg;
		#note YYY($text);
		lives_ok {
			$lis_msg = Message->create_message( $text );
		};
		ok $lis_msg->is_complete, 'complete message';
	};

	subtest "Create incomplete message" => sub {
		my $lis_msg;
		my $incomplete_text = $text =~ s/\r\QL|1\E\r\Z//gsr;
		#note YYY($incomplete_text);
		lives_ok {
			$lis_msg = Message->create_message(
				$incomplete_text
			);
		};
		ok ! $lis_msg->is_complete, 'incomplete message';
	};

	subtest "Create message with tree" => sub {
		my $lis_msg;
		lives_ok {
			$lis_msg = $MessageWTree->create_message( $text );
		};
		my $node_tree_names = join "", $lis_msg->tree_dag_node->dump_names;
		note $node_tree_names;
		is $node_tree_names, <<~EOF, 'Dump of nodes matches expected tree';
		root
		  0|H
		    1|P|1
		      2|C|1
		      3|O|1
		        4|R|1
		          5|C|1
		          6|C|2
		      7|O|2
		        8|R|1
		        9|R|2
		        10|R|3
		      11|O|3
		        12|R|1
		      13|O|4
		        14|R|1
		          15|C|1
		    16|P|2
		      17|O|1
		        18|R|1
		        19|R|2
		        20|R|3
		        21|R|4
		      22|O|2
		        23|R|1
		    24|P|3
		      25|O|1
		        26|R|1
		        27|R|2
		        28|R|3
		        29|R|4
		      30|O|2
		        31|R|1
		        32|R|2
		        33|R|3
		        34|R|4
		        35|R|5
		        36|R|6
		        37|R|7
		        38|R|8
		        39|R|9
		        40|R|10
		        41|R|11
		        42|R|12
		  43|L|1
		EOF
	};

	subtest "Does not start with message header" => sub {
		my $lis_msg;
		my $no_header = $text =~ s/\A\QH|\E[^\r]+\r//gsr;
		#note YYY($no_header);
		throws_ok {
			$lis_msg = Message->create_message(
				$no_header
			);
		} 'failure::LIS02A2::Codec::InvalidMessageHeader';
	};
};

done_testing;
