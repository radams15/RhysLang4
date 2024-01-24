package Visitor;

use warnings;
use strict;

use v5.10.1;
use experimental 'switch';

use Data::Dumper;

use Scope;
use Asm;

my $HEAP_SIZE = 512; # bytes

sub wordsize {
	my $class = shift;
	my ($name) = @_;
	
	$class->{datasizes}->{NAMES}->{uc $name};
}

my @CALL_REGISTERS = qw/di si dx cx/;


sub typeof {
	my $class = shift;
	my ($data) = @_;
	
	if(ref $data eq 'HASH') {
		given($data->{datatype}) {
			when ('STRING') { return "STR" }
			when ('NUMBER') { return "INT" }
		}
		
		given($data->{type}) {
			when ('VARIABLE') {
				my $var = $class->{scope}->get($data->{name}->{value});
				return $var->{datatype};
			}
			
			when ('CALL') {
				my $var = $class->{scope}->get($data->{callee}->{name}->{value});
				printf "; %s returns: %s\n", $data->{callee}->{name}->{value}, $var->{def}->{returns}->{value};
				return $var->{def}->{returns}->{value};
			}
			
			when ('METHOD_CALL') {
				my $var = $class->{scope}->get(&method_hash($data->{callee}->{name}->{value}, $data->{name}->{value}));
				printf "; %s returns: %s\n", $data->{name}->{value}, $var->{def}->{returns}->{value};
				return $var->{def}->{returns}->{value};
			}
		}
	}
		
	return 'INT' if($data =~ /\d+(?:\.\d+)?/);
	
	return 'STR';
}

sub sizeof_type {
	my $class = shift;
	my ($type) = @_;
	
	if($type =~ m/INT|STR|PTR/i) {
		return $class->{datasizes}->{'INT'};
	} elsif(my $var = $class->{scope}->get($type)) {
		my $size = 0;
		for(@{$var->{def}->{attributes}}) {
			$size += $class->sizeof($_);
		}
		return $size;
	} else {
		die "Unknown type: $type";
	}
}

{
	my $label_count = 0;
	sub generate_labels {
		my ($type) = @_;
		
		my $start = '.'.$type.'_'.$label_count;
		
		$label_count++;
		
		($start, $start.'_end');
	}
}

sub sizeof {
	my $class = shift;
	my ($data) = @_;
	
	given ($data->{type}) {
		when ('LITERAL') {
			return $class->sizeof_type($class->typeof($data->{value}));
		}
		
		when ('VARIABLE') {
			my $var = $class->{scope}->get($data->{name}->{value});
			return $class->sizeof_type($class->typeof($var->{type}));
		}
		
		when ('INDEX') {
			my $indexed = $data->{value};
			my $indexed_type = $class->typeof($indexed);
			
			given ($indexed_type) {
				when('STR') { return $class->sizeof_type('INT') } # e.g. a char.
				default { die "Cannot index '$indexed_type'" }
			}
		}
		
		when ('MY') {
			my $type = $data->{datatype}->{value};
			return $class->sizeof_type($type);
		}
		
		when ('CALL') {
			my $sub = $class->{scope}->get($data->{callee}->{name}->{value});
			return $class->sizeof_type($sub->{def}->{returns}->{value});
		}
		
		when ('COMPARISON') { return $class->sizeof_type('INT') }
		
		default { die "Unknown sizeof type: " . $data->{type} }
	}
}

my $level = 0;

sub new {
	my $class = shift;
	my $registers = shift;
	my $datasizes = shift;
	my ($preface) = @_;

	my $global_scope = Scope->new;

	my $this = bless {
		in_sub => 0,
		in_struct => 0,
		scope => $global_scope,
		strings => [],
		subs => {},
		registers => $registers,
		datasizes => $datasizes,
		preface => $preface,
		
		global_scope => $global_scope,
	}, $class;
	
	$this->{call_registers} = [
		reg('A'),
		reg('B'),
		reg ('C'),
		reg ('D')
	];
	
	$this->{stack_offset} = -($this->sizeof_type('PTR'));
	
	$this;
}

sub expel {
	for(@_) {
		print '', ("\t" x $level), $_, "\n";
	}
}

sub inc {
	my $class = shift;
	
	$level++;
}

sub dec {
	my $class = shift;
	
	$level--;
}

sub visit {
	my $class = shift;
	my ($expr) = @_;
	
	my $func_name = "visit_" . lc $expr->{type};
	
	unless($class->can($func_name)) {
		warn "Undefined function: Visitor::$func_name\n";
		return;
	}
	
	return $class->$func_name(@_);
}

sub visit_all {
	my $class = shift;
	
	map {$class->visit($_)} @_;
	
	halt;
	
	dump_asm;
}

sub prologue {
    #&push(reg('BP')),
    #&mov(reg('BP'), reg('SP'));
    &enter;
}

sub epilogue {
    #&mov(reg('SP'), reg('BP')),
    #&pop(reg('BP'))
    &leave,
    &ret;
}


sub visit_program {
	my $class = shift;
	my ($program) = @_;
	
	expel($class->{preface}) if $class->{preface};
	
	&label('_start');
	&call('main');
	
	$class->{global_scope}->set('_heap_top', {
		type => 'GLOBAL',
		name => '_heap_top',
		datatype => 'PTR',
	});
	
	$class->visit_all(@{$program->{body}});
	
	$class->inc;
	for(@{$class->{strings}}) {
		expel($_);
	}
	
	$class->dec;
    raw('_heap', '', $HEAP_SIZE);
	#expel("_heap: times $HEAP_SIZE db 0");
	#expel("_heap_top: ".$class->wordsize('PTR')." _heap");
}

sub method_hash {
	my ($struct_name, $meth_name, $params) = @_;
		
	$struct_name.'___'.$meth_name; 
}

sub visit_struct {
	my $class = shift;
	my ($struct) = @_;
	
	my %indexes;
	my $current_index = 0;
	for my $attr (@{$struct->{attributes}}) {
		my $size = $class->sizeof_type($attr->{datatype}->{value});
		$indexes{$attr->{name}->{value}} = $current_index;
		$current_index += $size;
	}
		
	$struct->{indexes} = \%indexes;
	
	$class->{global_scope}->set($struct->{name}->{value}, {
		type => 'GLOBAL',
		name => $struct->{name}->{value},
		datatype => 'STRUCT',
		def => $struct,
	});
	
	my $prev_struct = $class->{in_struct};
	$class->{in_struct} = $struct;
	
	for my $meth (@{$struct->{methods}}) {
		unless($meth->{static}) {
			$meth->{arity}++;
			${$meth->{params}}->unshift(this => $struct->{name}->{value}); # Unshift is like push put to front.
		}
		
		$meth->{name}->{value} = &method_hash($struct->{name}->{value}, $meth->{name}->{value}, $meth->{params});
		
		$class->visit($meth);
	}
	
	$class->{in_struct} = $prev_struct;
}

sub visit_sub {
	my $class = shift;
	my ($sub) = @_;
	
	my $sub_name = $sub->{name}->{value};
	
	$class->{subs}->{$sub_name} = $sub;
	$class->{global_scope}->set($sub_name, {
		type => 'GLOBAL',
		name => $sub_name,
		datatype => 'SUB',
		def => $sub,
	});
	
	return unless defined $sub->{block};
	
	my $old_sub = $class->{in_sub};
	my $old_stack_offset = $class->{stack_offset};
	
	&label($sub_name);
	$class->{in_sub} = $sub;
	$class->{scope} = $class->{scope}->child;
	$class->{stack_offset} = -$class->sizeof_type('PTR');
	
	$class->inc;
	comment("Args: ", ${$sub->{params}}->keys);
	&prologue;
	
	my $arity = scalar ${$sub->{params}}->keys;
	
	my $used_regs=0;
	my ($register, $offset, $arg_size);
	
	my @call_regs = reverse(@{$class->{call_registers}}[0..$arity-1]);
	comment("Call registers: ", @call_regs);
	my $param_iterator = ${$sub->{params}}->iterator;
	while(my ($name, $type) = $param_iterator->()) {
		$register = $call_regs[$used_regs];

		$arg_size = $class->sizeof_type($type);
		$offset = $class->{stack_offset};
		&comment("$name @ bp+$offset");
		&push(reg $register);
		$class->{scope}->set($name, {
			type => 'LOCAL',
			offset => $offset,
			datatype => $type,
		});
		
		$class->{stack_offset} -= $arg_size;
		$used_regs++;
	}
	
	$class->visit($sub->{block});
		
	$class->dec;
	&label(".end_$sub_name");
	$class->inc;
	&epilogue;
	
	$class->{scope} = $class->{scope}->{parent};
	$class->{in_sub} = $old_sub;
	$class->{stack_offset} = $old_stack_offset;
	
	$class->dec;
	
	$sub->{returns};
}

sub visit_loop {
	my $class = shift;
	my ($loop) = @_;
	
	my ($start, $end) = generate_labels('loop');
	
	$class->dec; expel("$start:"); $class->inc;
	$class->visit($loop->{expr});
	expel(
		'cmp ' . register('ax') . ', 0',
		"je $end",
	);
	
	$class->visit($loop->{body});
	
	expel("jmp $start");
	
	$class->dec; expel("$end:"); $class->inc;
}

sub visit_if {
	my $class = shift;
	my ($if) = @_;
	
	my ($start, $end) = generate_labels('if');
	
	$class->visit($if->{expr});
	
	expel(
		'cmp ' . register('ax') . ', 0',
		"je $start",
	);
	
	expel('; TRUE:');
	$class->visit($if->{true});
	
	expel('; END TRUE');
	
	$class->dec; expel("$start:"); $class->inc;
	
	$class->visit($if->{false}) if defined $if->{false};
	
	expel("jmp $end");
	
	$class->dec; expel("$end:"); $class->inc;
	
	"INT";
}


sub visit_block {
	my $class = shift;
	my ($block) = @_;
	
	inc;
	map {$class->visit($_)} @{$block->{statements}};
	dec;
}

sub visit_assign {
	my $class = shift;
	my ($assign) = @_;
	
	$class->visit($assign->{value});
	
	my $var = $class->{scope}->get($assign->{name}->{value});
	
	given($var->{type}) {
		when('LOCAL') {
			print "; $assign->{name}->{value} @ $var->{offset}\n";
			
			expel('mov ' . register('bp', 1, $var->{offset}) . ', ' . register('ax'));
		}
		
		when('GLOBAL') {
			print "; $assign->{name} @ $var->{name}\n";
			
			expel('mov [' . $var->{name} . '], ' . register('ax'));
		}
	}
}

sub visit_get {
	my $class = shift;
	my ($get) = @_;
	
	my $value = $get->{name}->{value};
	my $from = $get->{expr}->{name}->{value};
	
	my $struct_type;
	if($from eq 'this') {
		$struct_type = $class->{in_struct};
	} else {
	    print "; From: $from\n";
		$struct_type = $class->{scope}->get(
			$class->{scope}->get($from)->{datatype}
		)->{def};
	}

	my $attr_offset = $struct_type->{indexes}->{$value};
	
	print "; Get $value from $from (Struct: $struct_type->{name}->{value}, Offset: $attr_offset)\n";
	
	#expel('mov '.register('ax').', '.register('bp', 1, $offset));
	$class->visit($get->{expr}); # Get struct ptr into ax
	expel('mov '.register('ax').', '.register('ax', 1, $attr_offset));
}

sub visit_set {
	my $class = shift;
	my ($set) = @_;
	
	my $value = $set->{name}->{value};
	my $from = $set->{expr}->{name}->{value};
	
	my $struct_type;
	if($from eq 'this') {
		$struct_type = $class->{in_struct};
	} else {
		$struct_type = $class->{scope}->get(
			$class->{scope}->get($from)->{datatype}
		)->{def};
	}
	
	my $offset = $struct_type->{indexes}->{$value};
	
	print "; set $value from $from (Struct: $struct_type->{name}->{value}, Offset: $offset)\n";
	
	$class->visit($set->{value});
	expel('push '.register('ax')); # bx => struct
	
	$class->visit($set->{expr});
	expel('pop '.register('dx')); # dx => assigned value

	expel('mov '.register('ax', 1, $offset).', '.register('dx')); # ax => attribute
}


sub get_flag {
	my $class = shift;
	my ($name) = @_;
		
	my $mask;
	given ($name) {
		when('ZF') { $mask = 0x0040 }
		
		when('CF') { $mask = 0x0001 }
		
		when('SF') { $mask = 0x0080 }
		
		when('OF') { $mask = 0x0800 }
		
		default { die "Unknown flag: $name" }
	}
	
	expel(
		'pushf',
		'pop ax',
		"xor ax, $mask",
	); # Flags in ax
}

sub cmp {
	my $class = shift;
	my ($a, $b, $op) = @_;
	
	my ($start, $end) = &generate_labels('cmp');
	
	expel(
		"cmp $a, $b",
	);
	
	my $jump_instr;
	given ($op) {
		when ('LESS') { $jump_instr = 'jl' }
		when ('GREATER') { $jump_instr = 'jg' }
		when ('EQUALS') { $jump_instr = 'je' }
		
		default { die "Unknown cmp op: $op" }
	}
	
	expel(
		"$jump_instr $start",
		"mov $a, 0",
		"jmp $end",
	);
	
	$class->dec; expel("$start:"); $class->inc;
	expel(
		"mov $a, 1",
		"jmp $end",
	);
	
	$class->dec; expel("$end:"); $class->inc;
}

sub visit_comparison {
	my $class = shift;
	my ($comparison) = @_;
	
	given($comparison->{op}->{name}) {
		when (/LESS|GREATER/) {
			$class->visit($comparison->{right});
			expel('push ' . register('ax'));
			$class->visit($comparison->{left});
			expel('pop ' . register('cx'));
			
			when('LESS') {
				$class->cmp(
					register('ax'),
					register('cx'),
					'LESS',
				);
			}
			
			when('GREATER') {
				$class->cmp(
					register('ax'),
					register('cx'),
					'GREATER',
				);
			}
		}

		default { die "Unknown term: $comparison->{op}->{name}" }
	}
}

sub visit_equality {
	my $class = shift;
	my ($equality) = @_;
	
	given($equality->{op}->{name}) {
		when (/BANG_EQUALS|EQUALS/) {
			$class->visit($equality->{left});
			expel('push ' . register('ax'));
			$class->visit($equality->{right});
			expel('pop ' . register('cx'));
			
			$class->cmp(
				register('ax'),
				register('cx'),
				'EQUALS',
			);
			
			when('BANG_EQUALS') {
				expel('not ' . register('ax')); # invert if !=
			}
		}

		default { die "Unknown term: $equality->{op}->{name}" }
	}
}

sub visit_term {
	my $class = shift;
	my ($term) = @_;
	
	given($term->{op}->{name}) {
		when ('PLUS') {
			$class->visit($term->{left});
			&push(reg 'A');
			$class->visit($term->{right});
			&pop(reg 'C');
			&add(reg('A'), reg('A'), reg('C'));
		}
		when ('MINUS') {
			$class->visit($term->{right});
			&push(reg 'A');
			$class->visit($term->{left});
			&pop(reg 'C');
			&sub(reg('A'), reg('A'), reg('C'));
		}
		
		default { die "Unknown term: $term->{op}->{name}" }
	}
}

sub visit_my {
	my $class = shift;
	my ($my) = @_;
	
	if($class->{in_sub}) {
		if(defined $my->{initialiser}) {
			$class->visit($my->{initialiser});
		} else {
			expel('xor ' . register('ax') . ', ' . register('ax'));
		}
		
		expel('push '. register('ax'));
		
		my $datatype;
				
		if(defined $my->{datatype}) {
			$datatype = $my->{datatype}->{value};
		} elsif (defined $my->{initialiser}) {
			$datatype = $class->typeof($my->{initialiser});
		} else {
			die "Declarations require either a declared datatype or an initialiser.";
		}
		
		print "; Name: $my->{name}->{value}, Datatype: $datatype\n";
		
		$class->{scope}->set_new($my->{name}->{value}, {
			type => 'LOCAL',
			offset => $class->{stack_offset},
			datatype => $datatype,
		});
		
		$class->{stack_offset} -= $class->sizeof_type($datatype);
		
		return $datatype;
	} else {
		my $datatype;
		
		given($my->{initialiser}->{type}) {
			when('LITERAL') {
				my $literal = $my->{initialiser};
				my $value = $literal->{value};
				
				my $name = $my->{name}->{value};
				
				$datatype = $class->typeof($literal);
				
				$class->{scope}->set_new($my->{name}->{value}, {
					type => 'GLOBAL',
					name => $name,
					datatype => $datatype,
				});
				
				if($datatype eq 'STR') {
					$class->get_str_ref($literal->{value}, $name);
				} else {
					push @{$class->{strings}}, "$name: dw $value";
				}
			}
			
			when('VARIABLE') {
				my $variable = $my->{initialiser};
				my $name = $my->{name}->{value};
				
				my $value = $variable->{name}->{value};
												
				$datatype = $class->typeof($variable);
				
				$class->{scope}->set_new($my->{name}->{value}, {
					type => 'GLOBAL',
					name => $name,
					datatype => $datatype,
				});
				
				push @{$class->{strings}}, "$name: dw $value";
			}
			
			default { die 'Globals must be literal or const variable!' }
		}

		return $datatype;
	}
}

sub visit_return {
	my $class = shift;
	my ($return) = @_;
	
	$class->visit($return->{value});
	
	&br('.end_'.$class->{in_sub}->{name}->{value});
}

sub visit_expression {
	my $class = shift;
	my ($expression) = @_;
	
	$class->visit($expression->{expr});
}

sub get_str_ref {
	my $class = shift;
	my ($val, $id) = @_;
	
	$id = ('str_' . (scalar @{$class->{strings}} + 1)) if not defined $id;
	
	my $len = length($val);
	
	my @str_vals = ();
	for(split /\\(\w)/, $val) {
		given ($_) {
			when ('n') {
				push @str_vals, ord "\n";
				$len--; # Length 1 less as removed '\\'.
			}
			
			when ('r') {
				push @str_vals, ord "\r";
				$len--; # Length 1 less as removed '\\'.
			}
			
			default { push @str_vals, "'$_'"; }
		}
	}
		
	my $str_data = join ', ', ($len, @str_vals, 0);
	push @{$class->{strings}}, "$id: db $str_data";
	
	$id;
}

sub visit_literal {
	my $class = shift;
	my ($literal) = @_;
	
	my $type = $class->typeof($literal);
		
	given ($type) {
		when ('STR') {
		    &mov(reg('A'), $class->get_str_ref($literal->{value}));
		}
		
		when ('INT') {
		    &mov(reg('A'), $literal->{value});
		}
	}
}

sub visit_variable {
	my $class = shift;
	my ($var) = shift;
	
	my $name = $var->{name}->{value};
	
	my $value = $class->{scope}->get($name);
	
	die "Unknown variable: $name" unless defined $value;
	
	given($value->{type}) {
		when ('LOCAL') {
			expel("mov ". register('ax') .", " . register('bp', 1, $value->{offset}));
		}
		
		when ('GLOBAL') {
			if($value->{datatype} eq 'PTR') {
			    mov reg('a'), ptr($value->{name});
			} else {
			    mov reg('a'), $value->{name};
			}
		}
		
		default {
			die "Unknown variable type: $value->{type}";
		}
	}
	
	$value->{datatype};
}

sub visit_index {
	my $class = shift;
	my ($index) = @_;
	
	my $type = $class->visit($index->{value});
	
	expel('push ' . register('ax'));

	$class->visit($index->{index});
	if($type eq 'STR') {
		expel('inc ' . register('ax')); # Go over the string length.
	}
	expel('push ' . register('ax'));

	expel('pop ' . register('si')); # si = index
	expel('pop ' . register('bx')); # bx = array
	expel('add ' . register('bx') . ', ' . register('si'));
	
	expel('xor ' . register('ax') . ', ' . register('ax'));
	expel('mov ' . register('al') . ', ' . register('bx', 1));
}

sub visit_sizeof {
	my $class = shift;
	my ($sizeof) = @_;
	
	my $size = $class->sizeof_type($sizeof->{value}->{value});
	expel('mov ' . register('ax') . ", $size");
}

sub visit_method_call {
	my $class = shift;
	my ($method) = @_;
	
	my ($name, $from) = ($method->{name}->{value}, $method->{callee}->{name}->{value});
	my $static = 1;
	
	if(my $struct = $class->{scope}->get($from)) {
		if($struct->{datatype} ne 'STRUCT') {
			print "; $from is of type: $struct->{datatype}";
			$from = $struct->{datatype};
			$static = 0;
		}
	}
	
	printf "; Call method %s from %s\n", $name, $from;
	
	my $struct_type = $class->{scope}->get($from)->{def};
	my ($method_name) = grep {$_->{name}->{value} =~ /___$name/} @{$struct_type->{methods}};
	
	my $fullname = $method_name->{name}->{value};
	print "; Call $from.$name\n";
	
	my @args = @{$method->{arguments}};
	unless($static) {
		unshift @args, {
			type => 'VARIABLE',
			name => $method->{callee}->{name},
		};
	}
	
	$class->visit_call({
		type => 'CALL',
		arguments => \@args,
		callee => {
			type => 'ASM',
			str => {
				value => 'mov '.register('ax').", $fullname",
			},
		}
	});
}

sub visit_call {
	my $class = shift;
	my ($call) = @_;

	my @args = @{$call->{arguments}};
	my $num_args = scalar @args;
	
	for my $arg (@args) {
		$class->visit($arg);
		
		&push(reg 'A');
	}
	
	
	my @reversed_registers = ( @{$class->{call_registers}}[0..$num_args-1] );
	for my $register(@reversed_registers) {
	    &pop($register);
	}
	
	$class->visit($call->{callee});
	&call(reg 'A');
}

sub visit_asm {
	my $class = shift;
	my ($asm) = @_;
	
	my $val = $asm->{str}->{value};
	
	eval($val);
}

1;
