# Here's a little language with
#   numbers             (Num)
#   plus operators      (Sum)
#   variable references (Var)
#   variable bindings   (Scope)

use strict;
use warnings;

use Carp;
use Data::Dumper;

use lib ".";
use CalcLexer qw|
   $lexer
|;

use AlgebraicData qw|
   Else
|;

use ParseData qw|
   num var scope sum
   Num Var Scope Sum
|;

use Parser qw|
   expression
   show
|;

# ---------------------------------------------------------------------------- (
sub evaluate {
   my $expr = shift; 
   my $env  = shift || {};
   $expr->(
      Num  { shift },
      Sum { evaluate(shift,$env)+evaluate(shift,$env) },
      Var {
         my $var=shift;
         $env->{$var} || die "unknown variable $var"
      },
      Scope {
         # let x => s in t
         my ($x=>$s,$t) = @_;
         my $env2 = { %$env }; # shallow copy
         $env2->{$x} = evaluate($s,$env);
         evaluate($t,$env2)
      },
   )
}

sub pev {
   my $expr = shift; 
   my $env  = shift || {};
   $expr->(
      Num { $expr },
      Sum {
         my ($l,$r) = @_;
         pev($l,$env)->(
            Num {
               my $lval = shift;
               pev($r,$env)->(
                  Num { 
                     my $rval = shift;
                     num($lval+$rval)
                  },
                  Else { $expr },
               )
            },
            Else { $expr },
         )
      },
      Var {
         my ($v) = @_;
         defined $env->{$v} ? num($env->{$v}) : $expr
      },
      Scope {
         # let x => s in t
         my ($x=>$s,$t) = @_;
         my $ps = pev($s,$env);
         $ps->(
            Num {
               my $val = shift;
               my $env2 = { %$env }; # shallow copy
               $env2->{$x} = $val;
               pev($t,$env2);
            },
            Else {
               my $pt = pev($t,$env);
               return scope($x,$ps,$pt);
            },
         ),
      },
   )
}

# ---------------------------------------------------------------------------- )
# ---------------------------------------------------------------------------- (

my $tests = [
   sum(num(2),num(3)),
   sum(var('x'),num(3)),
   scope(
      x => sum(num(2),num(3)),
      sum(var('x'),var('x'))
   ),
   scope(
      y => sum(var('x'),num(3)),
      sum(var('y'),var('y'))
   ),
];

foreach my $t (@$tests) {
   printf "%4d ",    evaluate($t,{x=>4});
   printf "%-20s ",  show($t);
   printf "%-20s\n", show(pev($t));
}

# ---------------------------------------------------------------------------- )
# ---------------------------------------------------------------------------- (
# End-to-end test
# string is lexed, parsed, partially evaluated, then pretty printed.
my $strs = [
   "2+3",
   "x+3",
   "let x => 2+3 in x+x",
   "let y => x+3 in y+y",
];

foreach my $s (@$strs) {
   my $t = expression( $CalcLexer::lexer->($s));
   printf "%4d ",    evaluate($t,{x=>4});
   printf "%-20s ",  show($t);
   printf "%-20s\n", show(pev($t));
}

# ---------------------------------------------------------------------------- )
