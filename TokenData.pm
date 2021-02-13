package TokenData;

use strict;
use warnings;

use AlgebraicData qw|
   Else
|;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(|
   lit name let be in lpar rpar plus
   Lit Name Let Be In LPar RPar Plus
   eqtok
   showtok
   dumptok
   |);

#(
# Constructors for tokens
sub lit   { my @data = @_; bless sub { my $action = {@_}->{LIT}   || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub name  { my @data = @_; bless sub { my $action = {@_}->{NAME}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub let   { my @data = @_; bless sub { my $action = {@_}->{LET}   || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub be    { my @data = @_; bless sub { my $action = {@_}->{BE}    || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub in    { my @data = @_; bless sub { my $action = {@_}->{IN}    || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub lpar  { my @data = @_; bless sub { my $action = {@_}->{LPAR}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub rpar  { my @data = @_; bless sub { my $action = {@_}->{RPAR}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}
sub plus  { my @data = @_; bless sub { my $action = {@_}->{PLUS}  || {@_}->{ELSE}; $action->(@data)}, 'Token'}

# Pattern Matching for tokens
sub Lit   (&) { LIT   => shift }
sub Name  (&) { NAME  => shift }
sub Let   (&) { LET   => shift }
sub Be    (&) { BE    => shift }
sub In    (&) { IN    => shift }
sub LPar  (&) { LPAR  => shift }
sub RPar  (&) { RPAR  => shift }
sub Plus  (&) { PLUS  => shift }

#)

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

1;
