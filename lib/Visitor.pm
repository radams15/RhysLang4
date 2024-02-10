package Visitor;

use warnings;
use strict;

use v5.10.1;
use experimental 'switch';
no warnings 'deprecated';

use Data::Dumper;

use Scope;
use Asm;

my $HEAP_SIZE = 512; # bytes

sub wordsize {
	my $class = shift;
	my ($name) = @_;
	
	$class->{datasizes}->{NAMES}->{uc $name};
}


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
				&comment(sprintf "%s returns: %s\n", $data->{callee}->{name}->{value}, $var->{def}->{returns}->{value});
				return $var->{def}->{returns}->{value};
			}
			
			when ('METHOD_CALL') {
				my $var = $class->{scope}->get(&method_hash($data->{callee}->{name}->{value}, $data->{name}->{value}));
				&comment(sprintf "; %s returns: %s\n", $data->{name}->{value}, $var->{def}->{returns}->{value});
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
my $initial_stack_offset;

sub new {
	my $class = shift;

	my $global_scope = Scope->new;

	my $this = bless {
		in_sub => 0,
		in_struct => 0,
		scope => $global_scope,
		strings => [],
		subs => {},
		datasizes => {
			INT => 1,
	        PTR => 1
		},
		
		global_scope => $global_scope,
	}, $class;
	
	$initial_stack_offset = 0; #-$this->sizeof_type('INT');
	
	$this->{stack_offset} = $initial_stack_offset;
	
	$this;
}

sub expel {
	die "Disabled\n";
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
}

sub prologue {
    #&op_push(reg('BP')),
    #&mov(reg('BP'), reg('SP'));
    &enter;
}

sub epilogue {
    #&mov(reg('SP'), reg('BP')),
    #&op_pop(reg('BP'))
    &leave,
    &ret;
}


sub visit_program {
	my $class = shift;
	my ($program) = @_;
	
    my $heap_addr = raw('_heap', '', $HEAP_SIZE);
    raw('_heap_top', pack('s<', $heap_addr), 1);
	
	expel($class->{preface}) if $class->{preface};
	
	&label('_start');
	&call('main');
	&halt;
	
	$class->{global_scope}->set('_heap_top', {
		type => 'GLOBAL',
		name => '_heap_top',
		datatype => 'PTR',
	});
	
	$class->visit_all(@{$program->{body}});
	
	for(@{$class->{strings}}) {
		my ($name, $len, $data) = @$_;
		raw($name, $data, $len);
	}
	
	#expel("_heap: times $HEAP_SIZE db 0");
	#expel("_heap_top: ".$class->wordsize('PTR')." _heap");
	
	dump_asm;
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
	$class->{stack_offset} = $initial_stack_offset;
	
	$class->inc;
	comment("Args: ", ${$sub->{params}}->keys);
	&prologue;
	
	my $arity = scalar ${$sub->{params}}->keys;
	
	my ($register, $offset, $arg_size);
	
	my $param_iterator = ${$sub->{params}}->iterator;
	while(my ($name, $type) = $param_iterator->()) {
		$arg_size = $class->sizeof_type($type);
		$offset = $class->{stack_offset}+3;
		&comment("$name @ bp+$offset");
		$class->{scope}->set($name, {
			type => 'LOCAL',
			offset => $offset,
			datatype => $type,
		});
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
	
	&label($start);
	$class->visit($loop->{expr});
	
	&comp(reg('A'), 0);
	&brz($end);
	
	$class->visit($loop->{body});
	
	&br($start);
	
    &label($end);
}

sub visit_if {
	my $class = shift;
	my ($if) = @_;
	
	my ($start, $end) = generate_labels('if');
	
	$class->visit($if->{expr});
	
	&comp(reg('A'), 0);
	&brz($start);

	&comment('TRUE:');
	$class->visit($if->{true});
	
	&comment('END TRUE');
	
	&label($start);
	
	$class->visit($if->{false}) if defined $if->{false};
	
	&br($end);
	
	&label($end);
	
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
			&comment("$assign->{name}->{value} @ $var->{offset}");
			
			&mov(ptr('BP', $var->{offset}), reg('A'))
		}
		
		when('GLOBAL') {
			&comment("$assign->{name} @ $var->{name}");
			
			&op_push(reg 'B');
			&mov(reg('B'), $var->{name});
			&mov(ptr('B'), reg('A'));
			&op_pop(reg 'B');
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

sub cmp {
	my $class = shift;
	my ($a, $b, $op, $inv) = (@_);
	
	my ($start, $end) = &generate_labels('cmp');
	
	&comp($a, $b);
	
	my $jump_instr;
	given ($op) {
		when ('LESS') { $jump_instr = \&brlz }
		when ('GREATER') { $jump_instr = \&brgz }
		when ('EQUALS') { $jump_instr = \&brz }
		
		default { die "Unknown cmp op: $op" }
	}
	
	$jump_instr->($start);
	&mov($a, 0);
	&br($end);
	
	&label($start);
	
	&mov($a, 1);

	&label($end);
	
	&op_not($a, $a) if $inv;
}

sub visit_comparison {
	my $class = shift;
	my ($comparison) = @_;
	
	given($comparison->{op}->{name}) {
		when (/LESS|GREATER/) {
			$class->visit($comparison->{right});
			&op_push(reg 'A');
			$class->visit($comparison->{left});
			&op_pop(reg 'C');
			
			my $name = $comparison->{op}->{name};
			my $inv = 0;
			
			if($name =~ /(LESS|GREATER)_EQUALS/) {
			    $inv = 1;

			    $name = 'GREATER' if($name =~ /LESS_EQUALS/);
			    $name = 'LESS' if ($name =~ /GREATER_EQUALS/);
			}
			
			$class->cmp(
				&reg('A'),
				&reg('C'),
				$name,
				$inv
			);
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
			&op_push(reg 'A');
			$class->visit($equality->{right});
			&op_pop(reg 'C');
			
			$class->cmp(
				reg('A'),
				reg('C'),
				'EQUALS',
			);
			
			when('BANG_EQUALS') {
			    &op_not(reg('A'), reg('A')); # Invert if not equal
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
			&op_push(reg 'A');
			$class->visit($term->{right});
			&op_pop(reg 'C');
			&add(reg('A'), reg('A'), reg('C'));
		}
		when ('MINUS') {
			$class->visit($term->{right});
			&op_push(reg 'A');
			$class->visit($term->{left});
			&op_pop(reg 'C');
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
		    &mov(reg('A'), 0);
		}
		
		&op_push(reg 'A');
		
		my $datatype;
				
		if(defined $my->{datatype}) {
			$datatype = $my->{datatype}->{value};
		} elsif (defined $my->{initialiser}) {
			$datatype = $class->typeof($my->{initialiser});
		} else {
			die "Declarations require either a declared datatype or an initialiser.";
		}
		
		&comment("Name: $my->{name}->{value}, Datatype: $datatype @ $class->{stack_offset}");
		
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
	
	my @str_vals = ();
	for(split /\\(\w)/, $val) {
		given ($_) {
			when ('n') {
				push @str_vals, "\n";
			}
			
			when ('r') {
				push @str_vals, "\r";
			}
			
			default { push @str_vals, "$_"; }
		}
	}
	
	$val = join('', @str_vals);
	my $len = length($val);

	push @{$class->{strings}}, [$id, $len+2, pack('s<', $len).$val];
	
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
		    &mov(reg('A'), ptr('BP', $value->{offset}));
		}
		
		when ('GLOBAL') {
			if($value->{datatype} eq 'PTR') {
			    mov(reg('a'), $value->{name});
			    mov(reg('a'), ptr('a'));
			} else {
			    mov(reg('a'), $value->{name});
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

    &op_push(reg 'B'); # back-up b

    &op_push(reg 'A');
    &op_pop(reg 'B');
    
	$class->visit($index->{index});
	if(uc $type eq 'STR') {
	    &add(reg('A'), reg('A'), 2); # Skip over string length
	}
	
	# b = val, a = index
	
	&add(reg('b'), reg('a'), reg('b'));
	&mov(reg('a'), ptr('b')); # deref b to a
	
	&op_pop(reg 'B'); # restore b
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
		
		&op_push(reg 'A');
	}
	
	$class->visit($call->{callee});
	&call(reg 'A');
	
	for(my $i=0 ; $i<$num_args ; $i++) {
		&op_pop(reg 'TMP');
	}
}

sub visit_asm {
	my $class = shift;
	my ($asm) = @_;
	
	my $val = $asm->{str}->{value};
	
	eval($val) or die $@;
}

1;
