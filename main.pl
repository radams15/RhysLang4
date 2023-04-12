#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';

use Token;
use Lexer;
use Parser;
use Visitor;

open FH, '<', 'in.rl';
my $data = join '', <FH>;
close FH;

my $lex = Lexer->new($data);

my $tokens = $lex->scan_tokens;

#print join "\n", (map {$_->str} @$tokens), "\n--------------\n\n";

my $parser = Parser->new($tokens);

my $visitor = Visitor->new;

my $program = $parser->parse;

$visitor->visit($program);
