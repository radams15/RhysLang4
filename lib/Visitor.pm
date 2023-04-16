package Visitor;

use warnings;
use strict;

use v5.10.1;
use experimental 'switch';

use Data::Dumper;

use Scope;

sub register {
	my $class = shift;
	
	my ($name, $address, $offset) = @_;
	
	my $out = '';
	
	$out .= '[' if $address;
	
	$out .= $class->{registers}->{uc $name};
	
	$out .= "+$offset" if $offset;
	
	$out .= ']' if $address;
	
	$out;
}

my @CALL_REGISTERS = qw/di si dx cx/;


sub typeof {
	my $class = shift;
	my ($data) = @_;
	
	if(ref $data eq 'HASH') {
		given($data->{type}) {
			when ('VARIABLE') {
				my $var = $class->{scope}->get($data->{name}->{value});
				return $var->{datatype};
			}
		}
	}
	
	return 'INT' if($data =~ /\d+(?:\.\d+)?/);
	
	return 'STR';
}

sub sizeof_type {
	my $class = shift;
	my ($type) = @_;
	
	given ($type) {
		when (/INT|STR|PTR/i) { $class->{datasizes}->{'INT'} }
		
		default { die "Unknown type: $type" }
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
		
		when ('CALL') {
			my $sub = $class->{scope}->get($data->{callee}->{name}->{value});
			return $class->sizeof_type($sub->{def}->{returns}->{value});
		}
		
		when ('COMPARISON') { return $class->sizeof_type('INT') }
		
		default { die "Unknown sizeof type: " . $data->{type} }
	}
}

sub new {
	my $class = shift;
	my $registers = shift;
	my $datasizes = shift;

	my $global_scope = Scope->new;

	my $this = bless {
		level => 0,
		in_sub => 0,
		scope => $global_scope,
		strings => [],
		subs => {},
		registers => $registers,
		datasizes => $datasizes,
		
		global_scope => $global_scope,
	}, $class;
	
	$this->{call_registers} = [
		$this->register('di'),
		$this->register('si'),
		$this->register('dx'),
		$this->register('cx'),
	];
	
	$this->{stack_offset} = -($this->sizeof_type('PTR'));
	
	$this;
}

sub expel {
	my $class = shift;
	
	for(@_) {
		print '', ("\t" x $class->{level}), $_, "\n";
	}
}

sub inc {
	my $class = shift;
	
	$class->{level}++;
}

sub dec {
	my $class = shift;
	
	$class->{level}--;
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


sub visit_program {
	my $class = shift;
	my ($program) = @_;
	
	$class->expel(
		'%macro PROLOGUE 0',
		'push ' . $class->register('bp'),
		'mov ' . $class->register('bp') . ', ' . $class->register('sp'),
		'%endmacro', '',

		'%macro EPILOGUE 0',
		'mov ' . $class->register('sp') . ', ' . $class->register('bp'),
		'pop ' . $class->register('bp'),
		'ret',
		'%endmacro', ''
	);
	
	$class->expel(
		"section .text\n",
		"global _start\n",
		"_start:",
		"\tcall main\n",
	);
	
	$class->visit_all(@{$program->{body}});
	
	$class->expel("\nsection .data:");
	$class->inc;
	for(@{$class->{strings}}) {
		$class->expel($_);
	}
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
	
	$class->expel("$sub_name:");
	$class->{in_sub} = $sub;
	$class->{scope} = $class->{scope}->child;
	$class->{stack_offset} = -$class->sizeof_type('PTR');
	
	$class->inc;
	$class->expel('PROLOGUE');
	
	my $used_regs=0;
	my ($register, $offset, $arg_size);
	while(my ($name, $type) = each %{$sub->{params}}) {
		$register = $class->{call_registers}[$used_regs];

		$arg_size = $class->sizeof_type($type);
		$offset = $class->{stack_offset};
		$class->expel("push $register");
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
	$class->expel(".end_$sub_name:");
	$class->inc;
	$class->expel('EPILOGUE');
	
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
	
	$class->dec; $class->expel("$start:"); $class->inc;
	$class->visit($loop->{expr});
	$class->expel(
		'cmp ' . $class->register('ax') . ', 0',
		"je $end",
	);
	
	$class->visit($loop->{body});
	
	$class->expel("jmp $start");
	
	$class->dec; $class->expel("$end:"); $class->inc;
}

sub visit_block {
	my $class = shift;
	my ($block) = @_;
	
	map {$class->visit($_)} @{$block->{statements}}
}

sub visit_assign {
	my $class = shift;
	my ($assign) = @_;
	
	$class->visit($assign->{value});
	
	my $var = $class->{scope}->get($assign->{name}->{value});
	
	print "; $assign->{name}->{value} @ $var->{offset}\n";
	
	$class->expel('mov ' . $class->register('bp', 1, $var->{offset}) . ', ' . $class->register('ax'));
}


sub get_flag {
	my $class = shift;
	my ($name) = @_;
	
	my $mask;
	given ($name) {
		when('ZF') { $mask = 0x0040 }
		
		when('CF') { $mask = 0x0001 }
		
		when('SF') { $mask = 0x0080 }
		
		default { die "Unknown flag: $name" }
	}
	
	$class->expel(
		'pushf',
		'pop ax',
		"xor ax, $mask",
	); # Flags in ax
}

sub cmp {
	my $class = shift;
	my ($a, $b, $op) = @_;
	
	$class->expel(
		'push ' . $class->register('cx'),
		"cmp $a, $b",
	);
	
	given ($op) { # https://c9x.me/x86/html/file_module_x86_id_288.html
		when('LESS') { # setl - zf=0 cf=1
			$class->get_flag('ZF');
			$class->expel(
				'not ax', # now zf must be 1
				'mov cx, ax', # NOT ZF -> CX
			);
			$class->get_flag('CF');
			
			$class->expel('and ax, cx'); # NOT ZF AND CF must be 1
		}
		
		when('GREATER') { # setl - zf=0 sf=0
			$class->get_flag('ZF');
			$class->expel(
				'mov cx, ax', # ZF -> CX
			);
			$class->get_flag('SF'); # SF -> AX
			
			$class->expel(
				'and ax, cx', # ZF AND SF must be 0
				'not ax' # must be 1
			);
		}
		
		default { die "Unknown cmp op: $op" }
	}
	
	$class->expel('pop ' . $class->register('cx'));
}

sub visit_comparison {
	my $class = shift;
	my ($comparison) = @_;
	
	given($comparison->{op}->{name}) {
		when (/LESS|GREATER/) {
			$class->visit($comparison->{left});
			$class->expel('push ' . $class->register('ax'));
			$class->visit($comparison->{right});
			$class->expel('pop ' . $class->register('cx'));
			
			when('LESS') {
				$class->cmp(
					$class->register('ax'),
					$class->register('cx'),
					'LESS',
				);
			}
			
			when('GREATER') {
				$class->cmp(
					$class->register('ax'),
					$class->register('cx'),
					'GREATER',
				);
			}
		}

		default { die "Unknown term: $comparison->{op}->{name}" }
	}
}

sub visit_term {
	my $class = shift;
	my ($term) = @_;
	
	given($term->{op}->{name}) {
		when ('PLUS') {
			$class->visit($term->{left});
			$class->expel('push ' . $class->register('ax'));
			$class->visit($term->{right});
			$class->expel('pop ' . $class->register('cx'));
			$class->expel('add ' . $class->register('ax') . ', ' . $class->register('cx'));
		}
		when ('MINUS') {
			$class->visit($term->{right});
			$class->expel('push ' . $class->register('ax'));
			$class->visit($term->{left});
			$class->expel('pop ' . $class->register('cx'));
			$class->expel('sub ' . $class->register('ax') . ', ' . $class->register('cx'));
		}
		
		default { die "Unknown term: $term->{op}->{name}" }
	}
}

sub visit_my {
	my $class = shift;
	my ($my) = @_;
	
	$class->visit($my->{initialiser});
	$class->expel('push '. $class->register('ax'));
	
	my $datatype = $class->typeof($my->{initialiser}->{value});
	
	$class->{scope}->set_new($my->{name}->{value}, {
		type => 'LOCAL',
		offset => $class->{stack_offset},
		datatype => $datatype,
	});
	
	$class->{stack_offset} -= $class->sizeof($my->{initialiser});
	
	$datatype;
}

sub visit_return {
	my $class = shift;
	my ($return) = @_;
	
	$class->visit($return->{value});
	
	$class->expel("jmp .end_$class->{in_sub}->{name}->{value}");
}

sub visit_expression {
	my $class = shift;
	my ($expression) = @_;
	
	$class->visit($expression->{expr});
}

sub get_str_ref {
	my $class = shift;
	my ($val) = @_;
	
	my $id = 'str_' . (scalar @{$class->{strings}} + 1);
	
	my $len = length($val) + 1; # +1 for NULL-termination.
	
	my @str_vals = ();
	for(split /\\(\w)/, $val) {		
		if($_ eq 'n') {
			push @str_vals, ord "\n";
			$len--; # Length 1 less as removed '\\'.
		} else {
			push @str_vals, "'$_'";
		}
	}
		
	my $str_data = join ', ', ($len, @str_vals, 0);
	push @{$class->{strings}}, "$id: db $str_data";
	
	"$id";
}

sub visit_literal {
	my $class = shift;
	my ($literal) = @_;
	
	my $reg = $class->register('ax');
	
	my $type = $class->typeof($literal->{value});
	
	given ($type) {
		when ('STR') {
			$class->expel("mov $reg, " . $class->get_str_ref($literal->{value}))
		}
		
		when ('INT') {
			$class->expel("mov $reg, $literal->{value}")
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
			$class->expel("mov ". $class->register('ax') .", " . $class->register('bp', 1, $value->{offset}));
		}
		
		when ('GLOBAL') {
			$class->expel("mov ". $class->register('ax') .", $value->{name}");
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
	
	$class->expel('push ' . $class->register('ax'));

	$class->visit($index->{index});
	if($type eq 'STR') {
		$class->expel('inc ' . $class->register('ax')); # Go over the string length.
	}
	$class->expel('push ' . $class->register('ax'));

	$class->expel('pop ' . $class->register('si')); # si = index
	$class->expel('pop ' . $class->register('bx')); # bx = array
	$class->expel('add ' . $class->register('bx') . ', ' . $class->register('si'));
	
	$class->expel('xor ' . $class->register('ax') . ', ' . $class->register('ax'));
	$class->expel('mov ' . $class->register('al') . ', ' . $class->register('bx', 1));
}

sub visit_call {
	my $class = shift;
	my ($call) = @_;
	
	my @args = @{$call->{arguments}};
	my $num_args = scalar @args;
	
	for my $arg (@args) {
		$class->visit($arg);
		
		$class->expel("push " . $class->register('ax'));
	}
	
	
	my @reversed_registers = reverse( @{$class->{call_registers}}[0..$num_args-1] );
	for my $register(@reversed_registers) {		
		$class->expel("pop $register");
	}
	
	$class->visit($call->{callee});
	$class->expel("call " . $class->register('ax'));
}

sub visit_asm {
	my $class = shift;
	my ($asm) = @_;
	
	$class->expel($asm->{str}->{value});
}

1;
