package Visitor;

use warnings;
use strict;

use v5.10.1;
use experimental 'switch';

use Data::Dumper;

use Scope;

my @PROLOGUE = ("push bp", "mov bp, sp");
my @EPILOGUE = ("pop bp", "ret");

my %REGISTERS = (
	AX => 'ax',
	AH => 'ah',
	AL => 'al',
	BX => 'bx',
	BH => 'bh',
	BL => 'bl',
	CX => 'cx',
	CH => 'ch',
	CL => 'cl',
	DX => 'dx',
	DH => 'dh',
	DL => 'dl',
	SI => 'si',
	DI => 'di',
	SP => 'sp',
	BP => 'bp',
	CS => 'cs',
	DS => 'ds',
	SS => 'ss',
	ES => 'es',
);

sub register {
	my ($name, $address, $offset) = @_;
	
	my $out = '';
	
	$out .= '[' if $address;
	
	$out .= $REGISTERS{uc $name};
	
	$out .= "+$offset" if $offset;
	
	$out .= ']' if $address;
	
	$out;
}

sub typeof {
	my ($data) = @_;
	
	return 'INT' if($data =~ /\d+(?:\.\d+)?/);
	
	return 'STR';
}

sub sizeof_type {
	my ($type) = @_;
	
	given ($type) {
		when ('INT') { return 4 }
		when ('STR') { return 4 }
		when ('PTR') { return 4 }
		
		default { die "Unknown type: $type" }
	}
}

sub sizeof {
	my ($data) = @_;
	
	given ($data->{type}) {
		when ('LITERAL') {
			return sizeof_type(typeof($data->{value}));
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
		
		global_scope => $global_scope,
		stack_offset => -4,
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
	
	#map {$class->visit($_)} @{$program->{body}};
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
	
	my $old_sub = $class->{in_sub};
	my $old_stack_offset = $class->{stack_offset};
	
	$class->expel("$sub_name:");
	$class->{in_sub} = $sub;
	$class->{scope} = $class->{scope}->child;
	
	$class->inc;
	$class->expel(@PROLOGUE);
	$class->visit($sub->{block});
	
	$class->expel(@EPILOGUE);
	
	$class->{scope} = $class->{scope}->{parent};
	$class->{in_sub} = $old_sub;
	$class->{stack_offset} = $old_stack_offset;
	
	$class->dec;
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
	
	$class->{scope}->set_new($my->{name}->{value}, {
		type => 'LOCAL',
		offset => $class->{stack_offset},
	});
	
	$class->{stack_offset} += sizeof($my->{initialiser});
}

sub visit_return {
	my $class = shift;
	my ($return) = @_;
	
	$class->visit($return->{value});
	
	$class->expel(@EPILOGUE);
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
	
	push @{$class->{strings}}, "$id: db '$val'";
	
	"[$id]";
}

sub visit_literal {
	my $class = shift;
	my ($literal) = @_;
	
	my $reg = register('ax');
	
	given (typeof($literal->{value})) {
		when ('STR') {
			$class->expel("mov $reg, " . $class->get_str_ref($literal->{value}))
		}
		
		when ('INT') {
			$class->expel("mov $reg, $literal->{value}")
		}
	}
}

1;
