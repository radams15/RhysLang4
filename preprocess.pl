#!/usr/bin/perl

use warnings;

use Getopt::Long;

my %defines;

my @search = (
	'.',
	'./stdlib',
);

my @files;

sub add_file { push @files, $_[0]; }

GetOptions (
	'search=s' => \@search,
	'defines=s' => \%defines,
	'<>' => \&add_file,
);

sub cmd_include {
	while(my($key, $value) = each(%defines)) { $deflist .= "-d $key='$value' " }

	for my $module (@_) {
		my $path;
		my $found = 0;
		for(@search) {
			$path = "$_/$module.rl";
			if (-e $path) {
				system("perl $0 $deflist $path");
				$found = 1;
				last;
			}
		}
		
		die "Could not find module '$module' in any search paths" unless $found;
	}
}

sub cmd_if {
	my ($condition, @rest) = @_;
	
	if($defines{$condition}) {
		my $rest = join ' ', @rest;
		&line($rest);
	}
}

sub cmd_echo {
	print join(' ', @_), "\n";
}

sub cmd {
	my ($name, $arg_str) = @_;
	
	my $func = "cmd_$name";

	die "Undefined macro: '$name'" unless(defined(&$func));
	
	my @args = split /\s/, $arg_str;
	
	&$func(@args);
}

sub line {
	my ($line) = @_;
	
	if($line =~ /^\%([a-zA-Z]*)\s+(\S[\s\S]*)$/g) {
		&cmd($1, $2);
	} else {
		print "$line\n";
	}
}

for(@files) {
	open FH, '<', $_;

	while(<FH>) {
		chomp;
		
		&line($_);
	}
	
	close FH;
}
