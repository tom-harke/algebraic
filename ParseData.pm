package ParseData;

use strict;
use warnings;

use AlgebraicData qw|
   Else
|;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(|
   num var scope sum
   Num Var Scope Sum
   |);

# ---------------------------------------------------------------------------- (
# Token Enums & Parse Trees -- Made with Algebraic Data Types


# Constructors for parse trees
sub num   { my @data = @_; bless sub { my $action = {@_}->{NUM}   || {@_}->{ELSE}; $action->(@data)}, 'PTree'}
sub var   { my @data = @_; bless sub { my $action = {@_}->{VAR}   || {@_}->{ELSE}; $action->(@data)}, 'PTree'}
sub scope { my @data = @_; bless sub { my $action = {@_}->{SCOPE} || {@_}->{ELSE}; $action->(@data)}, 'PTree'}
sub sum   { my @data = @_; bless sub { my $action = {@_}->{SUM}   || {@_}->{ELSE}; $action->(@data)}, 'PTree'}

# Pattern Matching for parse trees
sub Num   (&) { NUM   => shift }
sub Var   (&) { VAR   => shift }
sub Scope (&) { SCOPE => shift }
sub Sum   (&) { SUM   => shift }

# ---------------------------------------------------------------------------- )


1;
