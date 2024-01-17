package Asm;

use warnings;
use strict;
use utf8;
use 5.030_000;

use Exporter 'import';

our @EXPORT_OK = qw//;
our @EXPORT = qw/ reg label comment halt mov add sub mul div shr shl nand xor br brz brnz in out comp not or and push pop call ret dump_asm /;

my %REGISTERS = (
    A => 'r0',
    B => 'r1',
    C => 'r2',
    D => 'r3',
    E => 'r4',
    F => 'r5',
    SP => '%sp',
    BP => '%bp',
    RET => '%ret',
    TMP => '%tmp',
    IP => '%ip',
);

my %labels;
my $p = 0;
my @code;

sub reg {
    my $name = shift;
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
    push @code, ['; ' . join(' ', @_)];
}


sub triad {
    my ($instr, $a, $b, $c) = @_;
    
    die "Invalid triad $instr" unless $a and $b and $c;
    
    push @code, [$instr, $a, $b, $c];
    $p += 4;
}


sub halt {
    push @code, "halt";
    $p += 1;
}

sub mov {
    my ($a, $b) = @_;
    
    push @code, ['mov', $a, $b];
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

sub push {
    my ($a) = @_;
    
    &comment('push', $a);
    
    &mov(reg('sp', 1), $a);
    &sub(reg('sp'), reg('sp'), '$1');
}

sub pop {
    my ($a) = @_;
    
    &comment('pop', $a);
    
    &add(reg('sp'), reg('sp'), '$1');
    &mov($a, reg('sp', 1));
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

sub parse {
    my ($name, @args) = @_;
    
    return @_ if $name =~ /^;/;
    
    my @out;
    for my $arg (@args) {
        if(defined $labels{$arg}) {
            CORE::push @out, $labels{$arg};
        } elsif ($arg =~ /^\d+$/g) {
            CORE::push @out, "\$$arg";
        } else {
           CORE::push @out, $arg;
        }
    }
    
    $name, '    ', join ', ', @out;
}


sub dump_asm {
    say '****** Code Dump ******';
    
    for my $line (@code) {
        say parse @$line;
    }
}

1;
