package Epidermis::Protocol::CLSI::LIS::LIS02A2::Message::Role::TreeDAG;
# ABSTRACT: A role to create a Tree::DAG_Node from records

use Moo::Role;
use namespace::autoclean;

use Tree::DAG_Node;

use Const::Fast;

const our $ROOT_NODE_NAME => 'root';
const our $ROOT_NODE_IDX => -1;

has tree_dag_node => (
	is => 'ro',
	lazy => 1,
	default => sub {
		Tree::DAG_Node->new({
			name => $ROOT_NODE_NAME,
			attributes => { index => $ROOT_NODE_IDX }
		});
	},
);

has _tree_index_to_node => (
	is => 'ro',
	default => sub {
		my ($self) = @_;

		return +{
			$ROOT_NODE_IDX => $self->tree_dag_node,
		}
	},
);

has _tree_parent_to_child => (
	is => 'ro',
	default => sub { +{} },
);


requires '_records_stack';

after 'add_record' => sub {
	my ($self) = @_;

	my @stack = ( $ROOT_NODE_IDX, @{ $self->_records_stack } );

	for my $index (reverse 1..@stack-1) {
		my $parent_idx = $stack[$index-1];
		my $child_idx = $stack[$index  ];

		last if exists $self->_tree_parent_to_child->{$parent_idx}{$child_idx};

		$self->_tree_parent_to_child->{$parent_idx}{$child_idx} = 1;
		my $parent = $self->_tree_index_to_node->{$parent_idx};
		my $child_record = $self->records->[$child_idx];
		my $child_type_id = $child_record->type_id;
		my $child_seq = $child_record->can('sequence') ?  "|" . $child_record->sequence->{data} : '';
		my $child = $self->_tree_index_to_node->{$child_idx} = Tree::DAG_Node->new({
			name => "$child_idx|$child_type_id$child_seq",
			attributes => { index => $child_idx }
		});

		$parent->add_daughter( $child );
	}
};

1;
