#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;

my %OPS = (
        NOOP => [0x00, ''],
    	PUSH => [0x01, ''],
    	CLEAR => [0x02, ''],
    	DROP => [0x03, ''],
    	LDVAL => [0x04, 'w'],
    	LDADDR => [0x05, 'w'],
    	LDLREF => [0x06, 'w'],
    	LDGLOB => [0x07, 'w'],
    	LDLOCL => [0x08, 'w'],
    	STGLOB => [0x09, 'w'],
    	STLOCL => [0x0a, 'w'],
    	STINDR => [0x0b, ''],
    	STINDB => [0x0c, ''],
    	INCGLOB => [0x0d, 'w'],
    	INCLOCL => [0x0e, 'w'],
    	INCR => [0x0f, 'w'],
    	STACK => [0x10, 'w'],
    	UNSTACK => [0x11, 'w'],
    	LOCLVEC => [0x12, ''],
    	GLOBVEC => [0x13, 'w'],
    	INDEX => [0x14, ''],
    	DEREF => [0x15, ''],
    	INDXB => [0x16, ''],
    	DREFB => [0x17, ''],
    	CALL => [0x18, 'w'],
    	CALR => [0x19, ''],
    	JUMP => [0x1a, 'w'],
    	RJUMP => [0x1b, 'r'],
    	JMPFALSE => [0x1c, 'w'],
    	JMPTRUE => [0x1d, 'w'],
    	FOR => [0x1e, 'w'],
    	FORDOWN => [0x1f, 'w'],
    	MKFRAME => [0x20, ''],
    	DELFRAME => [0x21, ''],
    	RET => [0x22, ''],
    	HALT => [0x23, 'w'],
    	NEG => [0x24, ''],
    	INV => [0x25, ''],
    	LOGNOT => [0x26, ''],
    	ADD => [0x27, ''],
    	SUB => [0x28, ''],
    	MUL => [0x29, ''],
    	DIV => [0x2a, ''],
    	MOD => [0x2b, ''],
    	AND => [0x2c, ''],
    	OR => [0x2d, ''],
    	XOR => [0x2e, ''],
    	SHL => [0x2f, ''],
    	SHR => [0x30, ''],
    	EQ => [0x31, ''],
    	NE => [0x32, ''],
    	LT => [0x33, ''],
    	GT => [0x34, ''],
    	LE => [0x35, ''],
    	GE => [0x36, ''],
    	UMUL => [0x37, ''],
    	UDIV => [0x38, ''],
    	ULT => [0x39, ''],
    	UGT => [0x3a, ''],
    	ULE => [0x3b, ''],
    	UGE => [0x3c, ''],
    	SKIP => [0x47, 'w'],
    	SCALL => [0x80, 'w']
);

my %ops = map {$OPS{$_}->[0] => [$_, $OPS{$_}->[1]]} keys %OPS;

sub debug {
    printf STDERR @_;
}

for(@ARGV) {
    my $size = (-s $_);

    open FH, '<', $_;
    binmode FH;
    
    my $head;
    read (FH, $head, 6) or die "Error reading $_!";
    die 'Not arg1 T3X program' unless $head eq "T3X0\x00\x00";
    
    my $i=0;
    my $op;
    
    while(1) {
        last if $i == $size;
        
        read (FH, $op, 1) or die "Error reading $_!";
        
        my ($opcode, $args);
        
        eval {
            ($opcode, $args) = @{$ops{ord $op}};
        } or die sprintf "Unable to parse opcode: 0x%02x\n", ord $op;
        
        my @args = map {
            my $arg;
            
            if($_ eq 'w') {
                read (FH, $arg, 2) or die "Error reading $_!";
                sprintf '0x%02x', unpack('trunc16', $arg);
            } elsif ($_ eq 'r') {
                read (FH, $arg, 1) or die "Error reading $_!";
                sprintf '0x%01x',  unpack('C', $arg);
            } else {
                die "Unknown argument type: $_\n";
            }
        } split //, $args;
        
        printf "%s %s\n", $opcode, join(', ', @args);
        
        $i++;
    }
    
    close FH;
}
