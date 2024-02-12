#!/usr/bin/perl

use strict;
use warnings;

use v5.10.1;
use experimental 'switch';
no warnings 'deprecated';

use Getopt::Long;
use Data::Dumper;

use lib './lib';

use Token;
use Lexer;
use Parser;
use Visitor;

use Registers_x86_16;
use Registers_x86_32;
use Registers_x86_64;

my $os = 'linux';
my $arch = 'x86_64';

my @files;
sub add_file {
	push @files, $_[0];
}

GetOptions(
	'arch=s' => \$arch,
	'os=s' => \$os,
	'<>' => \&add_file,
);

my $data;
if (scalar @files == 0){
	$data = join '', <>;
} else {
	$data = '';
	
	for(@files) {
		open FH, '<', $_;
		$data = join '', <FH>;
		close FH;
	}
}

my $lex = Lexer->new($data);
my $tokens = $lex->scan_tokens;

#print join("\n", map {$_->{name}} @$tokens), "\n";

my $parser = Parser->new($tokens);
my $program = $parser->parse;

#print Dumper $program;

my $visitor = Visitor->new();

$visitor->visit($program);
