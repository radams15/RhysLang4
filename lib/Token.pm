package Token;

use strict;
use warnings;

sub new {
	my $class = shift;
	my ($name, $value, $literal) = @_;

	bless {
		name => $name,
		value => $value,
		literal => $literal,
	}, $class;
}

sub str {
	my $class = shift;

	"$class->{name}($class->{value})";
}

1;
