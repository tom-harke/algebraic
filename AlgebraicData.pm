package AlgebraicData;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(|
   Else
   |);

# Pattern Matching -- generic
sub Else  (&) { ELSE  => shift }

1;
