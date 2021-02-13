use strict;
use warnings;

package LexGen;

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

1;
