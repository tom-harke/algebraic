package CalcLexer;

use strict;
use warnings;

use lib ".";
use LexGen;
use TokenData qw|
   lit name let be in lpar rpar plus
   Lit Name Let Be In LPar RPar Plus
   eqtok
   showtok
   dumptok
|;

# ---------------------------------------------------------------------------- (
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

our $lexer = LexGen::lexgen($lexdef);
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

1;
