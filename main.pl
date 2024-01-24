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

my ($register_func, $datasize_func);

my $preface;

if(uc $os eq 'DOS') {
	$preface .= "org 100h\n";
}

given ($arch) {
	when ('x86_64') {
		($register_func, $datasize_func) = (Registers_x86_64::registers, Registers_x86_64::datasizes);
	}
	
	when ('x86_32') {
		($register_func, $datasize_func) = (Registers_x86_32::registers, Registers_x86_32::datasizes);
	}
	
	when ('x86_16') {
		($register_func, $datasize_func) = (Registers_x86_16::registers, Registers_x86_16::datasizes);
	}
	
	default { die "Unknown arch: $arch" }
}

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

my $visitor = Visitor->new($register_func, $datasize_func, $preface);

$visitor->visit($program);
