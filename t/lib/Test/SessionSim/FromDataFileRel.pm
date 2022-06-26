package Test::SessionSim::FromDataFileRel;
# ABSTRACT: Read data from file relative to test file

use Mu;
extends 'Test::SessionSim::FromDataFile';

lazy data_path => sub { $0 =~ s/\.t$/.data.pl/r };

1;
