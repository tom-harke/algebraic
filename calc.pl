# Here's a little language with
#   numbers             (Num)
#   plus operators      (Sum)
#   variable references (Var)
#   variable bindings   (Scope)

# TODO
#  - associativity on (+) is wrong!
#  - partition into modules
#  - error messages
#  - line numbers
#  - pretty printer: omit unnecessary parens
#  - put (partial) type-checking into constructors
#    - can check that recursive subfields are blessed properly
#  - add another layer of indirection to tokenizer,
#    - between data & function put a hash
#      - key 'next' extracts next token
#      - key 'push' replaces tokens
#  - allow tokenizer to do multiline text
#
#  - make constructors into objects
#     - why??? so they know their own type?  doesn't sh
#  - bless constructors so that we can do ad-hoc overloading
#     - showtok ==> show
use strict;
use warnings;

use Carp;
use Data::Dumper;
# ---------------------------------------------------------------------------- (
# Token Enums & Parse Trees -- Made with Algebraic Data Types

# Constructors for tokens
sub lit   { my @data = @_; bless sub { my $action = {@_}->{LIT}   || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub name  { my @data = @_; bless sub { my $action = {@_}->{NAME}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub let   { my @data = @_; bless sub { my $action = {@_}->{LET}   || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub be    { my @data = @_; bless sub { my $action = {@_}->{BE}    || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub in    { my @data = @_; bless sub { my $action = {@_}->{IN}    || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub lpar  { my @data = @_; bless sub { my $action = {@_}->{LPAR}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub rpar  { my @data = @_; bless sub { my $action = {@_}->{RPAR}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub plus  { my @data = @_; bless sub { my $action = {@_}->{PLUS}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}

# Constructors for parse trees
sub num   { my @data = @_; bless sub { my $action = {@_}->{NUM}   || {@_}->{ELSE}; $action->(@data)}, 'PTree'}
sub var   { my @data = @_; bless sub { my $action = {@_}->{VAR}   || {@_}->{ELSE}; $action->(@data)}, 'PTree'}
sub scope { my @data = @_; bless sub { my $action = {@_}->{SCOPE} || {@_}->{ELSE}; $action->(@data)}, 'PTree'}
sub sum   { my @data = @_; bless sub { my $action = {@_}->{SUM}   || {@_}->{ELSE}; $action->(@data)}, 'PTree'}

# Pattern Matching -- generic
sub Else  (&) { ELSE  => shift }

# Pattern Matching for tokens
sub Lit   (&) { LIT   => shift }
sub Name  (&) { NAME  => shift }
sub Let   (&) { LET   => shift }
sub Be    (&) { BE    => shift }
sub In    (&) { IN    => shift }
sub LPar  (&) { LPAR  => shift }
sub RPar  (&) { RPAR  => shift }
sub Plus  (&) { PLUS  => shift }

# Pattern Matching for parse trees
sub Num   (&) { NUM   => shift }
sub Var   (&) { VAR   => shift }
sub Scope (&) { SCOPE => shift }
sub Sum   (&) { SUM   => shift }

# ---------------------------------------------------------------------------- )
# ---------------------------------------------------------------------------- (
# Equality on Tokens

sub eqtok {
   my ($a,$b) = @_;
   $a->(
      Lit {
         my $aval = shift;
         $b->(
            Lit  { $aval eq shift ? 1 : 0 },
            Else { 0 },
         )
      },
      Name {
         my $aval = shift;
         $b->(
            Name { $aval eq shift ? 1 : 0 },
            Else { 0 },
         )
      },
      Let  { $b->( Let  {1}, Else {0}) },
      Be   { $b->( Be   {1}, Else {0}) },
      In   { $b->( In   {1}, Else {0}) },
      LPar { $b->( LPar {1}, Else {0}) },
      RPar { $b->( RPar {1}, Else {0}) },
      Plus { $b->( Plus {1}, Else {0}) },
   )
}

sub dumptok {
   my ($a,$b) = @_;
   $a->(
      Lit  { my $v = shift; "lit($v)"  },
      Name { my $v = shift; "name($v)" },
      Let  { "let()"  },
      Be   { "be()"   },
      In   { "in()"   },
      LPar { "lpar()" },
      RPar { "rpar()" },
      Plus { "plus()" },
   )
}

sub showtok {
   my ($a,$b) = @_;
   $a->(
      Lit  { my $v = shift; $v  },
      Name { my $v = shift; $v },
      Let  { "let" },
      Be   { "=>"  },
      In   { "in"  },
      LPar { "("   },
      RPar { ")"   },
      Plus { "+"   },
   )
}

my @foo = ( &lit(7), &lit(8), &name('x'), &name('y'), &let(), &be(), &in(), &lpar(), &rpar(), &plus() );
foreach my $a ( @foo ) {
   foreach my $b ( @foo ) {
      print eqtok($a,$b);
   }
   print "\n";
}

# ---------------------------------------------------------------------------- )
# ---------------------------------------------------------------------------- (
# Lexer Builder.
# Based on one in HOP but simplified (It won't accept multi-line comments or
# multi-line strings)
# 
# TODO: add line & column numbers

sub lexgen {
   # Level 1: a lexer generator
   # Input is an arrayref-to-hashref defining tokens
   #  - each hash in the array
   #     - defines one class of token
   #     - has a 'regex' key whose value defines the token, and has 0 or 1 capture
   #     - has a 'cons'  key whose value is the name of the token constructor which is applied to the captured value (if any)
   my $lexdef = shift;
   return sub {
      # Level 2: a lexer
      # Input is the string to be lexically analyzed
      my $input = shift;
      my @redo  = ();
      return sub {
         # Level 3: a lazy stream of tokens.
         # If there are no arguments, it returns the 1 next token.
         # If arguments, they are pushed back onto the 'head' of the stream
         if (@_) {
            push @redo, (reverse @_);
            return;
         }
         if (@redo) {
            return pop @redo;
         }
         # untested )
         TOKEN: {
            foreach my $hash (@$lexdef) {
               next unless $input =~ /\G $hash->{regex} /gcx;
               return $hash->{cons}->($1)
            }
            redo TOKEN           if $input =~ /\G \s+ /gcx;
            return [ERROR => $1] if $input =~ /\G (.) /gcx; # TODO: replace [_=>_] with an error message
            return;
         }
      };
   };
}

# ---------------------------------------------------------------------------- )
# ---------------------------------------------------------------------------- (
# Lexer.


my $lexdef = [
   { cons => \&lit,  regex => qr|(\d+)| },
   { cons => \&let,  regex => qr|let| },
   { cons => \&be,   regex => qr|=>| },
   { cons => \&in,   regex => qr|in| },
   { cons => \&plus, regex => qr|\+| },
   { cons => \&lpar, regex => qr|\(| },
   { cons => \&rpar, regex => qr|\)| },
   { cons => \&name, regex => qr/([A-Za-z_][A-Za-z_0-9]*)/ },
];

my $lexer = lexgen($lexdef);
# ---------------------------------------------------------------------------- )
# ---------------------------------------------------------------------------- (
# Lexer.
# Test.
my $q = [
   { in  => "let x => 1 in (x+2)"
   , out => [let(),name('x'),be(),lit(1),in(),lpar(),name('x'),plus(),lit(2),rpar()]
   },
   { in  => "let x => let y => 1 in y+2 in x+2"
   , out => [let(),name('x'),be(),let(),name('y'),be(),lit(1),in(),name('y'),plus(),lit(2),in(),name('x'),plus(),lit(2)]
   },
];


foreach my $item (@$q) {
   my $i = $lexer->($item->{in});

   # TODO convert this into some sort of test (
   #$i->(lit(7),plus());
   #$i->();
   #$i->();
   #)

   my $o = $item->{out};
   print "Checking tokenization of: $item->{in}\n";
   while (my $r = $i->()) {
      my $s = shift @$o || die "ran out";
      my $result = &eqtok($r,$s);
      printf "Tokens differ: %s != %s\n", dumptok($r), dumptok($s) unless $result == 1;
   }
}

# ---------------------------------------------------------------------------- )
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

my @fubar = (
   "x",
   "0",
   "1+2",
   "let x => 1 in x",
   "let x => 1 in (x+2)",
   "1+2+3+4",
);

foreach my $str (@fubar) {
   printf "%20s %20s\n", $str, show(expression( $lexer->($str) ));
}

# ---------------------------------------------------------------------------- )
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
         # let x=s in t
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
   my $t = expression( $lexer->($s));
   printf "%4d ",    evaluate($t,{x=>4});
   printf "%-20s ",  show($t);
   printf "%-20s\n", show(pev($t));
}

# ---------------------------------------------------------------------------- )
