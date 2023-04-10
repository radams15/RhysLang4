#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';

use Token;
use Lexer;

open FH, '<', 'in.rl';
my $data = join '', <FH>;
close FH;

my $lex = Lexer->new($data);

my $tokens = $lex->scan_tokens;

for (@$tokens) {
	print $_->str, "\n";
}
