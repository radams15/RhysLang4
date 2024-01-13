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
    	HALT => [0x23, ''],
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
    	SKIP => [0x3d, 'w'],
    	POP => [0x3e, ''],
    	SCALL => [0x3f, 'w']
);

my %ALIASES = (
    ENTER => 'MKFRAME',
    LEAVE => 'DELFRAME',
);

sub debug {
    printf STDERR @_;
}

my $p = 0;

my %strings;
my %consts;
my %labels;

open OUT, '>out.bin';
binmode OUT;
select OUT;

sub call2 {
        my ($type, $num, @args) = @_;

        my @out;

        my $ret = $p + (3*scalar(@args)) + 9;

        for(@args) {
            push @out, ['LDADDR', $_], ['PUSH'];
        }

        if($type eq 'SCALL') {
            push @out, ['LDADDR', $ret], ['PUSH'];
        } else {
            push @out, ['NOOP'], ['NOOP'], ['NOOP']
        }

        push @out, [$type, $num];
        
        push @out, ['DROP'], ['DROP'], ['DROP'];

        return @out;
}

sub calls {
        my $type = shift;
        
        return (
            ['LDADDR', '.+5'],
            ['PUSH'],
            [$type, @_]
        );
}

my %MACROS = (
    CALL2 => sub {&call2('CALL', @_)},
    CALLS => sub {&calls('CALL', @_)},
    SCALL2 => sub {&call2('SCALL', @_)},
    SCALLS => sub {&calls('SCALL', @_)},


    STR => sub {
        my ($name, @args) = @_;

        my $str = join ' ', @args;
        $str =~ s/\\n/\n/g;

        #$strings{$name} = $p+2;
        #&gen('RJUMP', length($str)+1); # Jump over the string
        #$p += length($str)+1;
        $strings{$name} = $p;
        
        debug "$name @ %02x\n", $p;
        
        $p += length($str)+1;

        print pack "a*C", $str, 0;

        return ();
    },

    CONST => sub {
        my ($name, @args) = @_;

        my $val = join ' ', @args;

        $consts{$name} = $val;

        return ();
    }
);

sub print_ops {
    for my $op (sort {hex($OPS{$a}->[0]) <=> hex($OPS{$b}->[0])} keys %OPS) {
        my ($opcode, $arg) = @{$OPS{$op}};
        debug "$op\{@{[sprintf '0x%02x', $opcode]}\}($arg)\n";
    }
}

if(scalar @ARGV == 0) {
    &print_ops;
    exit 0;
}


sub interp {
    my ($in) = @_;

    if($labels{$in}) {
        #debug "%s => %s\n", $in, $labels{$in};
        return $labels{$in};
    }

    if($strings{$in}) {
        #debug "%s => %s\n", $in, $strings{$in};
        return $strings{$in};
    }

    if($consts{$in}) {
        #debug "%s => %s\n", $in, $consts{$in};
        return $consts{$in};
    }

    return $p if($in eq '.');

    return hex($in) if($in =~ m/%0x[0-9a-f]+$/);
    
    return int($in) if($in =~ m/^\d+$/g);

    return 0;
}

sub parse {
    my ($in) = @_;

    if($in =~ /(.*)(\+|\-|\*|\/)(.*)/g) {
        my ($a, $b) = map {interp $_} ($1, $3);

        return eval "$a $2 $b";
    }

    return &interp($in);
}

sub gen {
    my ($op, @args) = @_;
    
    my ($opcode, $op_args);
    if($OPS{$op}) {
        ($opcode, $op_args) = @{$OPS{$op}};
    } elsif ($ALIASES{$op}) {
        ($opcode, $op_args) = @{$OPS{$ALIASES{$op}}};
    } else {
        die "Invalid opcode: $op\n"
    }

    die "Invalid number of arguments for opcode $op (Got @{[scalar(@args)]}, needed @{[length($op_args)]})\n"
        if(length($op_args) != scalar(@args));

    my $start = $p;

    print pack 'C', $opcode;

    $p++;

    my $i = 0;
    for my $arg (split //, $op_args) {
        next unless $arg;
        if($arg eq 'w') { # 16-bit word
            print pack 'S', &parse($args[$i]);
            $p += 2;
        } elsif ($arg eq 'r') { # 8-bit byte
            print pack 'C', &parse($args[$i]);
            $p++;
        } else {
            die "Invalid argument specifier: $arg\n";
        }
        $i++;
    }

    debug "%02x => $op\{%02x\}(@{[join ',', @args]})\n", $start, $opcode;
}

my @lines = <>;

for my $i(1..2) {
    seek OUT, 0, 0;
    print pack 'a6', "T3X0";
    $p=0;
    
    debug "\n**********\nPass $i\n**********\n\n";
    
    for(@lines) {
        chomp;
        s/;.*//g; # Remove comments
        next unless $_;
        
        if(/(.*):/) {
            debug "%s: (%02x)\n", $1, $p;
            $labels{$1} = $p;
        } else {
            my ($op, @args) = split / /;
            @args = grep {$_ ne ''} @args;

            if($MACROS{$op}) {
                for($MACROS{$op}->(@args)) {
                    &gen(@$_);
                }
                next;
            }

            &gen($op, @args);
        }
    }
}

close OUT;
