package Parser;

use strict;
use warnings;

use AlgebraicData qw|
   Else
|;

use TokenData qw|
   lit name let be in lpar rpar plus
   Lit Name Let Be In LPar RPar Plus
   eqtok
   showtok
   dumptok
|;

use ParseData qw|
   num var scope sum
   Num Var Scope Sum
|;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(|
   expression
   show
|);

# ---------------------------------------------------------------------------- (
# Parser
#
# Grammar:
#   expression = expression '+' expression
#              | number
#              | variable
#              | 'let variable '=>' expression 'in' expression
#              | '(' expression ')'
#
# Removing left recursion
#   expression  = ( number
#                 | variable
#                 | 'let variable '=>' expression 'in' expression
#                 | '(' expression ')'
#                 ) expression2
#   expression2 = '+' expression expression2
#               | ε

# TODO: do we want 1-token lookahead, or full backtracking?

sub bar {
   # TODO consider redo in AlgDT style
   # TODO consider combining foo & bar into a more generic token eater
   # TODO consider inlining
   my $tokens = shift;
   my $t = $tokens->();
   die "Expecting '=>'" unless eqtok($t, be());
}

sub foo {
   my $tokens = shift;
   my $t = $tokens->();
   die "Expecting 'in'" unless eqtok($t, in());
}

sub binder { # TODO consider inlining
   my $tokens = shift;
   my $name   = $tokens->();
   my $var = $name->(
      #Name { my $n = shift; $n },
      Name { shift },
      Else { die "oops" },
   );
   bar($tokens);
   my $e1     = expression($tokens);
   foo($tokens);
   my $e2     = expression($tokens);
   scope($var,$e1,$e2);
}

sub expression {
   my $tokens = shift;
   my $first  = $tokens->();
   my $x = $first->(
      Let  { binder($tokens); },
      Name { my $n = shift; var($n); },
      Lit  { my $n = shift; num($n); },
      LPar {
         my $e = expression($tokens);
         my $p = $tokens->();
         $p->(
            RPar { $e },
            Else { die "Right parenthesis ')' expected -- instead saw ", showtok($p), "'" },
         )
      },
      Else { die "One of TODO expected -- instead saw '", showtok($first), "'" },
   );
   expression2($x,$tokens);
}

sub expression2 {
   #   expression2 = '+' expression expression2 | ε
   my $lsum   = shift;
   my $tokens = shift;
   my $first  = $tokens->();

   return $lsum unless defined $first; # EOF
   $first->(
      Plus {
         my $rsum = expression($tokens);
         expression2(sum($lsum,$rsum), $tokens);
      },
      Else {
         $tokens->($first); # push $first back onto token stream ... TODO untested
         $lsum;
      },
   );
}

sub show {
   my $expr = shift; 
   my $env  = shift || {};
   $expr->(
      Num   { my ($n)    = @_; "$n" },
      Sum   { my ($l,$r) = @_; "(" . show($l) . "+" . show($r) . ")"},
      Var   { my ($v)    = @_; "$v" },
      Scope { my ($x=>$s,$t) = @_; "let $x => " . show($s) . " in " . show($t) },
   )
}

my @fubar = (
   "x",
   "0",
   "1+2",
   "let x => 1 in x",
   "let x => 1 in (x+2)",
   "1+2+3+4",
);

foreach my $str (@fubar) {
   printf "%20s %20s\n", $str, show(expression( $CalcLexer::lexer->($str) ));
}

# ---------------------------------------------------------------------------- )

1;
