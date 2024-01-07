#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

my %OPS;
my %REGS;
my %TRAPS;

open FH, '<ops.h';
my $i=0;
my $current;
for(<FH>) {
    if(/typedef enum ([a-zA-Z]*) \{/g) {
        $current = \%OPS if($1 eq 'Opcode');
        $current = \%REGS if($1 eq 'Register');
        $current = \%TRAPS if($1 eq 'Trap');

        $i=0;
    }

    if(/    (?:OP_)?([A-Z_0-9]+)/g) {
        $current->{$1} = $i;
        $i++;
    }
}
close FH;

my $code = <<EOF;
TRAP TRP_IN_U16
ADD2 R1,R0,x0
TRAP TRP_IN_U16
ADD1 R1,R1,R0
ADD2 R0,R1,x0
PUSH R0
TRAP TRP_OUT_U16
HALT
EOF

=pod

Instruction layout:

OP(4) ARG1(8)  ARG2(8)
____ ________ ________
=cut

for(split /\n/, $code) {
    my ($op, $args) = split / /;
    my $opcode = $OPS{$op} or die "Unknown opcode: $op\n";

    print pack('C', $opcode);

    # Pack 'v' = unsigned 16-bit short (little endian)

    if ($args) {
        for(split /,\s*/, $args) {
            if(defined $REGS{$_}) {
                print pack('v', $REGS{$_});
            } elsif(defined $TRAPS{$_}) {
                print pack('v', $TRAPS{$_});
            } elsif (/x([0-9]+)/) {
                print pack('v', $1);
            } else {
                printf STDERR "Failed to define: %s\n", $_;
            }
        }
    }
}
