package Lexer;

use v5.10.1;
use experimental 'switch';

use Keywords;

sub new {
	my $class = shift;
	my ($source) = @_;

	die 'Lexer requires source!' unless defined $source;

	bless {
		start => 0,
		current => 0,
		line => 1,
		tokens => [],
		source => $source,
	}, $class;
}

sub source_at {
	my $class = shift;

	my ($start, $end) = @_;
	$end = $end? $end : $start+1;

	substr($class->{source}, $start, $end-$start);
}

sub peek {
	my $class = shift;
	my $inc = shift // 0;

	$class->source_at($class->{current}, $inc);
}

sub advance {
	my $class = shift;
	my $cur = $class->{current}++;
	$class->source_at($cur);
}

sub at_end {
	my $class = shift;

	$class->{current} >= length $class->{source};
}

sub match {
	my $class = shift;
	my ($expected) = @_;

	unless ($class->at_end || $class->source_at($class->{current}) ne $expected) {
		$class->{current}++;
		return 1;
	}

	return 0;
}

sub add_token {
	my $class = shift;
	my ($type, $literal) = @_;

	my $value = $class->source_at($class->{start}, $class->{current});
	push @{$class->{tokens}}, Token->new($type, $value, $literal, $class->{line}, $class->{start});
}

sub scan_token {
	my $class = shift;

	my $c = $class->advance;

	given ($c) {
		when ('(') { $class->add_token('LEFT_PAREN') }
		when (')') { $class->add_token('RIGHT_PAREN') }
		when ('{') { $class->add_token('LEFT_BRACE') }
		when ('}') { $class->add_token('RIGHT_BRACE') }
		when ('[') { $class->add_token('LEFT_BRACKET') }
		when (']') { $class->add_token('RIGHT_BRACKET') }
		when (',') { $class->add_token('COMMA') }
		when ('.') { $class->add_token('DOT') }
		when ('-') { $class->add_token('MINUS') }
		when ('+') { $class->add_token('PLUS') }
		when ('*') { $class->add_token('MULTIPLY') }
		when ('/') { $class->add_token('DIVIDE') }
		when (';') { $class->add_token('SEMICOLON') }
		when (':') { $class->add_token('COLON') }
		
		when ('#') { $class->advance until($class->peek eq "\n" or $class->at_end) }

		when ('!') { $class->add_token($class->match('=')? 'BANG_EQUALS' : 'BANG') }
		when ('=') { $class->add_token($class->match('=')? 'EQUALS_EQUALS' : 'EQUALS') }
		when ('<') { $class->add_token($class->match('=')? 'LESS_EQUALS' : 'LESS') }
		when ('>') { $class->add_token($class->match('=')? 'GREATER_EQUALS' : 'GREATER') }

		when (/\'|\"/) { $class->string($c) }

		when (/\n/) { $class->{line}++ }
		when (/\s/) {  }

		default: {
			if ($c =~ /\d/) {
				$class->number;
			} elsif ($c =~ /[a-zA-Z_]/) {
				$class->identifier;
			} else {
				die "Unknown token: '$c'";
			}
		}
	}	
}

sub string {
	my $class = shift;
	my ($str_char) = @_;

	until ($class->peek eq $str_char or $class->at_end) {
		$class->{line}++ if $class->peek =~ /\n/;

		$class->advance;
	}

	$class->advance;

	my $value = $class->source_at($class->{start}+1, $class->{current}-1);
	$class->add_token('STRING', $value);
}

sub number {
	my $class = shift;

	while($class->peek =~ /\d/) {
		$class->advance;
	}

	if($class->peek eq '.' and $class->peek(1) =~ /\d/) {
		$class->advance;

		while($class->peek =~ /\d/) {
			$class->advance;
		}
	}

	$class->add_token('NUMBER', $class->source_at($class->{start}, $class->{current}));
}

sub identifier {
	my $class = shift;

	while($class->peek =~ /[a-zA-Z0-9_]/) {
		$class->advance;
	}

	my $value = $class->source_at($class->{start}, $class->{current});

	my $type = grep(/^$value$/, Keywords::keywords)? uc $value : 'IDENTIFIER';	

	$class->add_token($type);
}

sub scan_tokens {
	my $class = shift;

	until($class->at_end) {
		$class->{start} = $class->{current};
		$class->scan_token;
	}

	$class->add_token('EOF');

	$class->{tokens};
}


1;
