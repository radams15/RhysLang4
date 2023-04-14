package Visitor;

use warnings;
use strict;

use v5.10.1;
use experimental 'switch';

use Data::Dumper;

use Scope;

use Registers_x86_64;


sub register {
	my ($name, $address, $offset) = @_;
	
	my $out = '';
	
	$out .= '[' if $address;
	
	$out .= Registers::registers->{uc $name};
	
	$out .= "+$offset" if $offset;
	
	$out .= ']' if $address;
	
	$out;
}

=pod
sub prologue {
	(
		'mov ' . register('cx') . ', ' . register('bp'),
		'mov ' . register('bp') . ', ' . register('sp'),
	);
}

sub epilogue {
	(
		'mov ' . register('bp') . ', ' . register('cx'),
		'ret',
	);
}
=cut


sub prologue {
	(
		'push ' . register('bp'),
		'mov ' . register('bp') . ', ' . register('sp'),
	);
}

sub epilogue {
	(
		'mov ' . register('sp') . ', ' . register('bp'),
		'pop ' . register('bp'),
		'ret',
	);
}

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
	my ($type) = @_;
	
	given ($type) {
		when (/INT|STR|PTR/i) { Registers::datasizes->{'INT'} }
		
		default { die "Unknown type: $type" }
	}
}

sub sizeof {
	my $class = shift;
	my ($data) = @_;
	
	given ($data->{type}) {
		when ('LITERAL') {
			return sizeof_type($class->typeof($data->{value}));
		}
		
		when ('VARIABLE') {
			my $var = $class->{scope}->get($data->{name}->{value});
			return sizeof_type($class->typeof($var->{type}));
		}
		
		when ('INDEX') {
			my $indexed = $data->{value};
			my $indexed_type = $class->typeof($indexed);
			
			given ($indexed_type) {
				when('STR') { return sizeof_type('INT') } # e.g. a char.
				default { die "Cannot index '$indexed_type'" }
			}
		}
		
		default { die "Unknown type: " . $data->{type} }
	}
}

sub new {
	my $class = shift;

	my $global_scope = Scope->new;

	bless {
		level => 0,
		in_sub => 0,
		scope => $global_scope,
		strings => [],
		subs => {},
		call_registers => [
			register('di'),
			register('si'),
			register('dx'),
			register('cx'),
		],
		
		global_scope => $global_scope,
		stack_offset => -sizeof_type('PTR'),
	}, $class;
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
		"section .text\n",
		"global _start\n",
		"_start:",
		"\tcall main",
		"\n",
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
	});
	
	return unless defined $sub->{block};
	
	my $old_sub = $class->{in_sub};
	my $old_stack_offset = $class->{stack_offset};
	
	$class->expel("$sub_name:");
	$class->{in_sub} = $sub;
	$class->{scope} = $class->{scope}->child;
	$class->{stack_offset} = -sizeof_type('PTR');
	
	$class->inc;
	$class->expel(&prologue);
	
	my $used_regs=0;
	my ($register, $offset, $arg_size);
	while(my ($name, $type) = each %{$sub->{params}}) {
		$register = $class->{call_registers}[$used_regs];

		$arg_size = sizeof_type($type);
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
	$class->expel(&epilogue);
	
	$class->{scope} = $class->{scope}->{parent};
	$class->{in_sub} = $old_sub;
	$class->{stack_offset} = $old_stack_offset;
	
	$class->dec;
	
	$sub->{returns};
}

sub visit_block {
	my $class = shift;
	my ($block) = @_;
	
	map {$class->visit($_)} @{$block->{statements}}
}

sub visit_my {
	my $class = shift;
	my ($my) = @_;
	
	$class->visit($my->{initialiser});
	$class->expel('push '. register('ax'));
	
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
	
	my $len = length $val;
	
	push @{$class->{strings}}, "$id: db $len, '$val'";
	
	"$id";
}

sub visit_literal {
	my $class = shift;
	my ($literal) = @_;
	
	my $reg = register('ax');
	
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
			$class->expel("mov ". register('ax') .", " . register('bp', 1, $value->{offset}));
		}
		
		when ('GLOBAL') {
			$class->expel("mov ". register('ax') .", $value->{name}");
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
	
	$class->expel('push ' . register('ax'));

	$class->visit($index->{index});
	if($type eq 'STR') {
		$class->expel('inc ' . register('ax')); # Go over the string length.
	}
	$class->expel('push ' . register('ax'));
	
=pod
	$class->expel('pop ' . register('bx')); # bx = index
	$class->expel('pop ' . register('cx')); # cx = array
	$class->expel('add ' . register('cx') . ', ' . register('bx'));
	$class->expel('xor ' . register('ax') . ', ' . register('ax'));
	$class->expel('mov ' . register('al') . ', ' . register('cx', 1));
=cut

	$class->expel('pop ' . register('si')); # si = index
	$class->expel('pop ' . register('bx')); # bx = array
	$class->expel('add ' . register('bx') . ', rsi');
	
	$class->expel('xor ' . register('ax') . ', ' . register('ax'));
	$class->expel('mov ' . register('al') . ', ' . register('bx', 1));
}

sub visit_call {
	my $class = shift;
	my ($call) = @_;
	
	my @args = @{$call->{arguments}};
	my $num_args = scalar @args;
	
	for my $arg (@args) {
		$class->visit($arg);
		
		$class->expel("push " . register('ax'));
	}
	
	
	my @reversed_registers = reverse( @{$class->{call_registers}}[0..$num_args-1] );
	for my $register(@reversed_registers) {		
		$class->expel("pop $register");
	}
	
	$class->visit($call->{callee});
	$class->expel("call " . register('ax'));
}

sub visit_asm {
	my $class = shift;
	my ($asm) = @_;
	
	$class->expel($asm->{str}->{value});
}

1;
