#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use experimental "switch";

my %REGS = (
    A => '0',
    B => '1',
    C => '2',
    D => '3',
    E => '4',
    F => '5',
    IP => '10',
    SP => '11',
    BP => '11',
    RET => '12',
    TMP => '13',
);

my %OPS = (
    HALT => 0x0,
    MOVE => 0x1,
    ADD => 0x2,
    SUB => 0x2,
    MUL => 0x4,
    DIV => 0x5,
    SHR => 0x6,
    SHL => 0x7,
    NAND => 0x8,
    XOR => 0x9,
    BR => 0xa,
    BRZ => 0xb,
    BRNZ => 0xc,
    IN => 0xd,
    OUT => 0xe
);

sub debug {
    printf STDERR @_;
    print STDERR "\n";
}

sub read_short {
    my ($fh) = @_;
    
    my $out;
    
    read($fh, $out, 2)
        or return undef;
        
    unpack('v', $out);
}

sub read_prog {
    my ($file) = @_;
    
    open FH, '<', $file;
    binmode FH;
    my @prog;
    while(defined(my $i = &read_short(*FH))) {
        push @prog, $i;
    }
    close FH;
    
    @prog;
}

sub parse_type {
    my ($in) = @_;
    
    my %out;
    
    if(($in >> 15) & 1) {
        $out{type} = 'r';
        $out{val} = $in & ~(1 << 15);
    } else {
        $out{type} = 'i';
        $out{val} = $in;
    }
    
    if(($in >> 14) & 1) {
        $out{addr} = 1;
        $out{val} &= ~(1 << 14);
    } else {
        $out{addr} = 0;
    }
    
    \%out;
}


my @regs = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);


sub ip {
    $regs[$REGS{IP}]; 
}

sub set_ip {
    $regs[$REGS{IP}] = $_[0];
}

sub val {
    my ($arg) = @_;
    
    if($arg->{type} eq 'i') {
        return $arg->{val};
    } else {
        return $regs[$arg->{val}];
    }
    
    die sprintf "Unknown type: %s", $arg->{type};
}

sub set_val {
    my ($arg) = @_;
    
    if($arg->{type} eq 'i') {
        die "Cannot assign to integer";
    } else {
        return $regs[$arg->{val}];
    }
    
    die sprintf "Unknown type: %s", $arg->{type};
}

sub run {
    my ($file) = @_;

    my @prog = read_prog($file);
    
    while(1) {
        my $instr = $prog[ip];
        
        debug "OP: 0x%02x", $instr;
        
        given ($instr) {
            when ($OPS{MOVE}) {
                my @args = map {parse_type $_} @prog[ip()+1, ip()+2];

                die "Move destination must be a register" unless $args[0]->{type} eq 'r';
                
                @regs[$args[0]->{val}] = val($args[1]);
                
                set_ip(ip()+3);
            }
            
            when($OPS{SUB}) {
                my @args = map {parse_type $_} @prog[ip()+1, ip()+2, ip()+3];      
               
                die "Sub destination must be a register" unless $args[0]->{type} eq 'r';   

                @regs[$args[0]->{val}] = val($args[1]) + val($args[2]);

                set_ip(ip()+4);
            }
            
            when ($OPS{HALT}) {
                debug "Halt";
                last;
            }
            
            when ($OPS{BR}) {
                my @args = map {parse_type $_} @prog[ip()+1];
                
                debug "Branch to %02x", val($args[0]);
                
                set_ip(val($args[0]));
            }
            
            when($OPS{XOR}) {
                my @args = map {parse_type $_} @prog[ip()+1, ip()+2, ip()+3];      
               
                die "XOR destination must be a register" unless $args[0]->{type} eq 'r';   

                @regs[$args[0]->{val}] = val($args[1]) ^ val($args[2]);

                set_ip(ip()+4);
            }
            
            default {
                die sprintf "Unknown op: %04x", $instr;
            }
        }
    }
}

for(@ARGV) {
    run $_;
}
