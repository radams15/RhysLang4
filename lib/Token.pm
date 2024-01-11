package Token;

use strict;
use warnings;

sub new {
	my $class = shift;
	my ($name, $value, $literal, $line, $col) = @_;

	bless {
		name => $name,
		value => $value,
		literal => $literal,
		line => $line,
		col => $col,
	}, $class;
}

sub str {
	my $class = shift;

	"$class->{name}($class->{value}) - $class->{line}:$class->{col}";
}

1;
