package Asm;

use warnings;
use strict;
use utf8;
use 5.030_000;

use Exporter 'import';

use List::Util qw/ sum /;

our @EXPORT_OK = qw//;
our @EXPORT = qw/ reg ptr label comment halt mov add sub mul div shr shl nand xor br brz brnz in out comp not or and stackat push pop call ret dump_asm /;

my %REGISTERS = (
    A => 'r0',
    B => 'r1',
    C => 'r2',
    D => 'r3',
    E => 'r4',
    F => 'r5',
    G => 'r6',
    H => 'r7',
    I => 'r8',
    J => 'r9',
    IP => 'r10',
    SP => 'r11',
    BP => 'r12',
    RET => 'r13',
    TMP => 'r14',
);

my %OPS = (
    HALT => 0x0,
    MOVE => 0x1,
    ADD => 0x2,
    SUB => 0x3,
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

my %labels;
my $p = 0;
my @code;

sub debug {
    printf STDERR @_;
    print STDERR "\n";
}

sub ptr {
    my $name = shift;
    my $offset = shift // 0;
    
    reg($name, $offset, 1);
}

sub reg {
    my $name = shift;
    my $offset = shift // 0;
    my $ref = shift // 0;
    
    my $out;
    
    die "Unknown register $name" unless defined $REGISTERS{uc $name};
    
    $out .= '(' if($ref);
    $out .= $REGISTERS{uc $name} or die "Invalid register: '$name'\n";
    $out .= ')' if($ref);
    
    $out;
}

sub label {
    my ($name) = @_;
    
    &comment("Label: $name = $p");
    $labels{$name} = $p;
}

sub comment {
    #push @code, ['; ' . join(' ', @_)];
}


sub triad {
    my ($instr, $a, $b, $c) = @_;
    
    die "Invalid triad $instr" unless defined $a and defined $b and defined $c;
    
    push @code, [$instr, $a, $b, $c];
    $p += 4;
}


sub halt {
    push @code, ['halt'];
    $p += 1;
}

sub mov {
    my ($a, $b) = @_;
    
    push @code, ['move', $a, $b];
    $p += 3;
}

sub add {
    &triad('add', @_);
}

sub sub {
    &triad('sub', @_);
}

sub mul {
    &triad('mul', @_);
}

sub div {
    &triad('div', @_);
}

sub shr {
    &triad('shr', @_);
}

sub shl {
    &triad('shl', @_);
}

sub nand {
    &triad('nand', @_);
}

sub xor {
    &triad('xor', @_);
}

sub br {
    my ($addr) = @_;
    
    push @code, ['br', $addr];
    $p += 2;
}

sub brz {
    my ($addr) = @_;
    
    push @code, ['brz', $addr];
    $p += 2;
}

sub brnz {
    my ($addr) = @_;
    
    push @code, ['brnz', $addr];
    $p += 2;
}

sub in {
    my ($addr) = @_;
    
    push @code, ['in', $addr];
    $p += 2;
}

sub out {
    my ($addr) = @_;
    
    push @code, ['out', $addr];
    $p += 2;
}





## MACROS ##


sub comp {
    my ($a, $b) = @_;
    
    &comment('cmp', $a, $b);
    &triad('sub', reg('tmp'), $a, $b);
}

sub not {
    my ($a, $b) = @_;
    
    &comment('not', $a, $b);
    &triad('nand', $a, $b, $b);
}

sub or {
    my ($a, $b, $c) = @_;
    
    &comment('or', $a, $b, $c);
    
    &triad('nand', $c, $c, $c); # C = C NAND C
    &triad('nand', $b, $b, $b); # B = B NAND B
    &triad('nand', $a, $b, $c); # A = B NAND C
}

sub and {
    my ($a, $b, $c) = @_;
    
    &comment('and', $a, $b, $c);
    
    &triad('nand', $a, $b, $c); # A = B NAND C
    &not($a, $a);
}

sub stackat {
    my ($a, $b) = @_;
    
    &comment('stackat ', $b, ' to ', $a);
    
    &mov(reg('J'), reg('bp'));
    &sub(reg('J'), reg('J'), $b);
    &mov($a, reg('J'));
}

sub push {
    my ($a) = @_;
    
    &comment('push', $a);
    
    &sub(reg('sp'), reg('sp'), '1');
    &mov(reg('sp', 1), $a);
}

sub pop {
    my ($a) = @_;
    
    &comment('pop', $a);
    
    &mov($a, reg('sp', 1));
    &add(reg('sp'), reg('sp'), '1');
}

sub call {
    my ($a) = @_;
    
    &comment('call', $a);
    
    &push(reg('ip'));
    &br($a);
}

sub ret {
    &comment('ret');

    &pop(reg('ip'));
}

## Dumping ##

sub emit_short {
    my ($val) = @_;
    
    debug 'Emit %016b', $val;
    
    print pack('v', $val);
}

sub emit_reg {
    my ($val, $ref) = @_;
    
    $val |= 1 << 15;
    
    if($ref) {
        $val |= 1 << 14;
    } else {
        $val &= ~(1 << 14);
    }
    
    &emit_short($val);
}

sub emit_int {
    my ($val, $ref) = @_;
    
    $val &= ~(1 << 15);
    
    if($ref) {
        $val |= 1 << 14;
    } else {
        $val &= ~(1 << 14);
    }
    
    &emit_short($val);
}

sub emit {
    my ($hash) = @_;
    
    for (@_) {
        my %hash = %$_;
        
        if($hash{type} eq 'r') {
            &emit_reg($hash{val}, $hash{'ref'});
        } elsif ($hash{type} eq 'i') {
            &emit_int($hash{val}, $hash{'ref'});
        } elsif ($hash{type} eq 'o') {
            &emit_short($hash{val}, $hash{'ref'});
        } else {
            die "Unknown type: '$hash{type}'";
        }
    }
}

sub parse_elem {
    my ($arg) = @_;
    
    if(defined $labels{$arg}) {
        return {type => 'i', val => $labels{$arg}};
    } elsif ($arg =~ /^\d+$/g) {
        return {type => 'i', val => $arg};
    } elsif ($arg =~ /^r(\d+)$/g) {
        return {type => 'r', val => $1};
    } else {
       die "Unknown value: '$arg'";
    }
}

sub parse {
    my ($name, @args) = @_;
    
    return @_ if $name =~ /^;/;
    
    my $opcode = $OPS{uc $name};
    
    die "Unknown op: '$name'" unless defined $opcode;
    
    my @out = ({type => 'o', val => $opcode});
    
    debug "\n@_";
    
    for my $arg (@args) {
        my $ref = 0;
        if($arg =~ /\((.*)\)/g) {
            $ref = 1;
            $arg = $1;
        }
        
        my $val = &parse_elem($arg);
        
        $val->{'ref'} = $ref;
        
        CORE::push @out, $val;
    }
    
    @out;
}


sub dump_asm {
    my $size = sum (map {scalar @$_} @code);
    debug "Size: %d", $size;
    emit_short($size);
    
    for my $line (@code) {
        emit parse @$line;
    }
}

1;
