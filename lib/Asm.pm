package Asm;

use warnings;
use strict;
use utf8;
use 5.030_000;

use Exporter 'import';

use List::Util qw/ sum /;

our @EXPORT_OK = qw//;
our @EXPORT = qw/ reg ptr label comment enter leave brkpt halt mov add sub mul div shr shl nand xor br brz brnz in out comp not or and stackat push pop call ret raw dump_asm /;

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
    OUT => 0xe,
    BRKPT => 0xf,
    
    PUSH => 0x10,
    POP => 0x11,
    ENTER => 0x12,
    LEAVE => 0x13,
    CALL => 0x14
);

my %labels;

my $p = 0; # code pointer
my $dp = 0; # data pointer

my @code;
my @data;

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
    $out .= "+$offset" if $offset;
    $out .= ')' if($ref);
    
    $out;
}

sub enter {
	push @code, [$p, 'enter'];
	$p++;
	
	#&push(reg('BP')),
    #&mov(reg('BP'), reg('SP'));
}

sub leave {
	push @code, [$p, 'leave'];
	$p++;
	
	#&mov(reg('SP'), reg('BP')),
    #&pop(reg('BP'))
}


sub brkpt {
    push @code, [$p, 'brkpt'];
    $p++;
}

sub label {
    my ($name) = @_;
    
    $labels{$name} = $p;
    &comment("Label: $name = $labels{$name}");
}

sub comment {
    push @code, [$p, '; ' . join(' ', @_)];
}


sub triad {
    my ($instr, $a, $b, $c) = @_;
    
    die "Invalid triad $instr" unless defined $a and defined $b and defined $c;
    
    push @code, [$p, $instr, $a, $b, $c];
    $p++;
}


sub halt {
    push @code, [$p, 'halt'];
    $p++;
}

sub mov {
    my ($a, $b) = @_;
    
    push @code, [$p, 'move', $a, $b];
    $p++;
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
    
    push @code, [$p, 'br', $addr];
    $p++;
}

sub brz {
    my ($addr) = @_;
    
    push @code, [$p, 'brz', $addr];
    $p++;
}

sub brnz {
    my ($addr) = @_;
    
    push @code, [$p, 'brnz', $addr];
    $p++;
}

sub in {
    my ($addr) = @_;
    
    push @code, [$p, 'in', $addr];
    $p++;
}

sub out {
    my ($addr) = @_;
    
    push @code, [$p, 'out', $addr];
    $p++;
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
    
    #&comment('push', $a);
    #&mov(reg('sp'), $a);
    #&sub(reg('sp'), reg('sp'), '1');
    CORE::push @code, [$p, 'push', $a];
    $p++;
}

sub pop {
    my ($a) = @_;
    
    #&comment('pop', $a);
    #&add(reg('sp'), reg('sp'), '1');
    #&mov($a, reg('sp'));
    
    CORE::push @code, [$p, 'pop', $a];
    $p++;
}

sub call {
    my ($a) = @_;
    
    #&comment('call', $a);
    #&mov(reg('J'), reg('ip'));
    #&add(reg('J'), reg('J'), 4); # Increment ip by 4 - I don't know why 4 but it does work.
    #&push(reg('J')); # Push return vector
    #&br($a);
    
    CORE::push @code, [$p, 'call', $a];
    $p++;
}

sub ret {
    &comment('ret');

    &pop(reg('ip'));
}

sub raw {
    my ($name, $data, $len) = @_;
    
    &comment('Raw: ', $name);
    
    CORE::push @data, {data => $data, len => $len, addr => $dp};
    
    $labels{$name} = $dp;
    
    $dp += $len;
}

## Dumping ##

sub emit_short {
    my ($val) = @_;
    
    debug 'Emit %016b', $val;
    
    print pack('s<', $val);
}

sub emit_reg {
    my ($val, $ref, $offset) = @_;

    # bits 13 = offset sign
    $val |= ($offset<0? 1 : 0) << 13;
    # bits 12-2 = offset
    $val |= abs($offset) << 4;
 
    # bit 15 = register?
    $val |= 1 << 15;
    
    # bit 14 = reference?
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

sub emit_data {
    for my $data (@data) {
        emit_short($data->{len});
        emit_short($data->{addr});
        print pack("a$data->{len}", $data->{data});
    }
}

sub emit {
    my ($hash) = @_;
    
    for (@_) {
        my %hash = %$_;
        
        if($hash{type} eq 'c') {
            debug "Comment: %s", $hash{val};
        } elsif($hash{type} eq 'r') {
            &emit_reg($hash{val}, $hash{'ref'}, $hash{offset});
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
    } elsif ($arg =~ /^r(\d+)(?:\+(\-?\d+))?$/g) {
        my $offset = $2 // 0;
        return {type => 'r', val => $1, offset => $offset};
    } else {
       die "Unknown value: '$arg'";
    }
}

sub parse {
    my ($ip, $name, @args) = @_;
    
    return {type => 'c', val => join(' ', $name, @args)} if $name =~ /^;/;
    
    my $opcode = $OPS{uc $name};
    
    die "Unknown op: '$name'" unless defined $opcode;
    
    my @out = ({type => 'o', val => $opcode});
    
    debug "\n%02x => $name @args", $ip;
    
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
    my $data_size = sum (map {$_->{len}} @data) // 0;
    
    debug "Size: %d, %d", $size, $data_size;
    emit_short($size);
    emit_short($data_size);
    
    emit_data;
    
    for my $line (@code) {
        emit parse @$line;
    }
}

1;
