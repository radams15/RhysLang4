package Parser;

use warnings;
use strict;

use Devel::StackTrace;
use Hash::Ordered;

use Data::Dumper;

use constant (
	DEBUG => 1
);

sub new {
	my $class = shift;
	my ($tokens) = @_;

	bless {
		tokens => $tokens,
		current => 0,
	}, $class;
}

sub error {
	my ($str) = @_;
	
	print STDERR $str, "\n";
	
	print "\n", Devel::StackTrace->new(no_refs => 1)->as_string, "\n" if DEBUG;
	
	exit 1;
}

sub token {
	my $class = shift;
	my ($i) = @_;

	@{$class->{tokens}}[$i];
}

sub at_end {
	my $class = shift;

	$class->peek->{name} eq 'EOF';
}

sub peek {
	my $class = shift;
	my $inc = shift // 0;

	$class->token($class->{current}+$inc);
}

sub previous {
	my $class = shift;

	$class->token($class->{current}-1);
}

sub advance {
	my $class = shift;

	$class->{current}++ unless $class->at_end;

	$class->previous;
}


sub check {
	my $class = shift;
	my ($type) = @_;

	$class->peek->{name} eq $type
		unless $class->at_end;
}

sub consume {
	my $class = shift;
	my ($expected, $err_msg) = @_;

	my $token = $class->previous->str;

	error "$err_msg - At $token" unless $class->check($expected);
	
	$class->advance;
}

sub match {
	my $class = shift;

	if (grep {$class->check($_)} @_) {
		$class->advance;	
		return 1;
	}

	return 0;
}

sub parse {
	my $class = shift;

	$class->program;
}




sub program {
	my $class = shift;

	my @out;

	until($class->at_end) {
		push @out, $class->declaration;
	}


	return {
		type => 'PROGRAM',
		body => \@out,
	};
}

sub declaration {
	my $class = shift;

	return $class->var_declaration if $class->match('MY');

	$class->statement;
}

sub var_declaration {
	my $class = shift;

	my $name = $class->consume('IDENTIFIER', 'Variable must have identifier');

	my $initialiser;

	if($class->match('EQUALS')) {
		$initialiser = $class->expression;
	}
	
	$class->consume('SEMICOLON', "Declaration must end with ';'");

	return {
		type => 'MY',
		name => $name,
		initialiser => $initialiser,
	};
}

sub statement {
	my $class = shift;
	
	return $class->if_statement if($class->match('IF'));
	return $class->while_statement if($class->match('WHILE'));
	return $class->sub_def if($class->match('SUB'));
	return $class->return_statement if($class->match('RETURN'));
	return $class->block if($class->match('LEFT_BRACE'));

	return $class->expression_statement;	
}

sub expression_statement {
	my $class = shift;

	my $expr = $class->expression;

	$class->consume('SEMICOLON', "Expressions must end with ';'");

	return {
		type => 'EXPRESSION',
		expr => $expr,
	};
}

sub return_statement {
	my $class = shift;
	
	my $keyword = $class->previous;
	
	my $value;
	$value = $class->expression
		unless $class->check('SEMICOLON');
		
	$class->consume('SEMICOLON', "Return must end with ';'");
	
	return {
		type => 'RETURN',
		keyword => $keyword,
		value => $value,
	};
}

sub if_statement {
	my $class = shift;
	
	$class->consume('LEFT_PAREN', "If statement requires '('");
	my $expr = $class->expression;
	$class->consume('RIGHT_PAREN', "If statement requires closing ')'");
	
	
	my $true = $class->statement;
	
	my $false;
	if($class->match('ELSE')) {
		$false = $class->statement;
	}
	
	return {
		type => 'IF',
		expr => $expr,
		true => $true,
		false => $false, 
	};
}

sub while_statement {
	my $class = shift;
	
	$class->consume('LEFT_PAREN', "While statement requires '('");
	my $expr = $class->expression;
	$class->consume('RIGHT_PAREN', "While statement requires closing ')'");
	
	my $body = $class->statement;

	return {
		type => 'LOOP',
		expr => $expr,
		body => $body,
	};
}

sub block {
	my $class = shift;
	
	my @statements;
	until($class->check('RIGHT_BRACE') or $class->at_end) {
		push @statements, $class->declaration;
	}
	
	$class->consume('RIGHT_BRACE', "Block must end with '}'");
	
	return {
		type => 'BLOCK',
		statements => \@statements,
	};
}

sub sub_def {
	my $class = shift;

	my $name = $class->consume('IDENTIFIER', 'Sub requires name');
	$class->consume('LEFT_PAREN', "Sub requires '('"); 

	my $params = Hash::Ordered->new;
	unless ($class->check('RIGHT_PAREN')) {
		do {
			my $name = $class->consume('IDENTIFIER', 'Function declaration requires parameters');
			$class->consume('COLON', 'Function parameter requires type');
			my $type = $class->consume('IDENTIFIER', 'Function parameter requires type');

			$params->set($name->{value} => $type->{value});
		} while ($class->match('COMMA'));
	}

	$class->consume('RIGHT_PAREN', "Sub requires ')' after paremeter list!");
	$class->consume('COLON', "Sub requires type after paremeter list!");
	my $type = $class->consume('IDENTIFIER', "Sub requires type after paremeter list!");

	my $block;
	if($class->check('LEFT_BRACE')) {
		$class->consume('LEFT_BRACE', "Sub requires '{' to open code block");
		$block = $class->block;
	} else {
		$class->consume('SEMICOLON', "Sub declaration requires ';'.");
	}

	return {
		type => 'SUB',
		name => $name,
		params => \$params,
		returns => $type,
		block => $block,
		arity => scalar($params->keys),
	};
}

sub expression {
	my $class = shift;

	$class->assignment;
}

sub assignment {
	my $class = shift;
	
	my $expr = $class->equality;
	
	if($class->match('EQUALS')) {
		my $equals = $class->previous;
		my $value = $class->assignment;
		
		error "Invalid assignment target" unless $expr->{type} eq 'VARIABLE';
		
		my $name = $expr->{name};
		return {
			type => 'ASSIGN',
			name => $name,
			value => $value,
		};
	}
	
	$expr;
}

sub equality {
	my $class = shift;

	my $expr = $class->comparison;
	
	while($class->match(qw/BANG_EQUALS EQUALS_EQUALS/)) {
		my $op = $class->previous;
		my $right = $class->comparison;
		$expr = {
			type => 'EQUALITY',
			left => $expr,
			op => $op,
			right => $right,
		};
	}

	$expr;
}

sub comparison {
	my $class = shift;

	my $expr = $class->term;

	while($class->match(qw/GREATER GREATER_EQUALS LESS LESS_EQUALS/)) {
		my $op = $class->previous;
		my $right = $class->term;
		
		$expr = {
			type => 'COMPARISON',
			left => $expr,
			op => $op,
			right => $right,
		}
	}

	$expr;
}

sub term {
	my $class = shift;

	my $expr = $class->factor;

	while($class->match(qw/MINUS PLUS/)) {
		my $op = $class->previous;
		my $right = $class->factor;
		
		$expr = {
			type => 'TERM',
			left => $expr,
			op => $op,
			right => $right,
		}
	}

	$expr;
}

sub factor {
	my $class = shift;

	my $expr = $class->unary;

	while($class->match(qw/DIVIDE MULTIPLY/)) {
		my $op = $class->previous;
		my $right = $class->unary;
		
		$expr = {
			type => 'FACTOR',
			left => $expr,
			op => $op,
			right => $right,
		}
	}

	$expr;
}

sub unary {
	my $class = shift;

	if($class->match(qw/BANG MINUS/)) {
		my $op = $class->previous;
		my $right = $class->unary;
		return {
			type => 'UNARY',
			op => $op,
			right => $right,
		};
	}

	$class->index;
}

sub index {
	my $class = shift;
	
	my $expr = $class->asm;
	
	if($class->match('LEFT_BRACKET')) {
		my $index_expr = $class->expression;
		$class->consume('RIGHT_BRACKET', "Index requires closing ']'");
				
		return {
			type => 'INDEX',
			value => $expr,
			index => $index_expr,
		};
	}
	
	$expr;
}

sub asm {
	my $class = shift;

	if($class->match('ASM')) {
		$class->consume('LEFT_PAREN');
		my $str = $class->expression;
		$class->consume('RIGHT_PAREN');
		return {
			type => 'ASM',
			str => $str,
		};
	}

	$class->call;
}

sub call {
	my $class = shift;
	
	my $expr = $class->primary; # Left value
		
	while (1) {
		if($class->match('LEFT_PAREN')) {
			$expr = $class->finish_call($expr);
		} else {
			last;
		}
	}
	
	$expr;
}

sub finish_call {
	my $class = shift;
	my ($callee) = @_;
	
	my @arguments;
	unless($class->check('RIGHT_PAREN')) {
		do {
			push @arguments, $class->expression;
		} while($class->match('COMMA'));
	}
	
	my $paren = $class->consume('RIGHT_PAREN', "Expect ')' after subroutine call");
	
	return {
		type => 'CALL',
		callee => $callee,
		paren => $paren,
		arguments => \@arguments,
	};
}

sub primary {
	my $class = shift;

	if($class->match('FALSE')) {
		return {
			type => 'LITERAL',
			value => 0,
		};
	} elsif($class->match('TRUE')) {
		return {
			type => 'LITERAL',
			value => 1,
		};
	} elsif($class->match('NULL')) {
		return {
			type => 'LITERAL',
			value => undef,
		};
	} elsif($class->match(qw/NUMBER STRING/)) {
		return {
			type => 'LITERAL',
			value => $class->previous->{literal},
			datatype => $class->previous->{name},
		};
	} elsif($class->match('IDENTIFIER')) {
		return {
			type => 'VARIABLE',
			name => $class->previous,
		};
	} elsif($class->match('LEFT_PAREN')) {
		my $expr = $class->expression;
		$class->consume('RIGHT_PAREN', 'Expect \')\' after expression!');
		return {
			type => 'GROUPING',
			expr => $expr,
		};
	}
	
	error "Unknown primary: " . $class->peek->str;
}


1;
