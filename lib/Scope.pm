package Scope;

use warnings;
use strict;

sub new {
	my $class = shift;
	my ($parent) = @_;

	bless {
		parent => $parent,
		variables => {},
	}, $class;
}

sub get {
	my $class = shift;
	my ($name) = @_;
	
	eval {
		my $out = $class->get_scope_of($name)->{variables}->{$name};
	} or undef;
}

sub set_new {
	my $class = shift;
	my ($name, $value) = @_;
	
	$class->{variables}->{$name} = $value;
}

sub set {
	my $class = shift;
	my ($name, $value) = @_;
	
	my $scope = $class->get_scope_of($name) // $class;
	
	$scope->{variables}->{$name} = $value;
}

sub contains {
	my $class = shift;
	my ($name) = @_;
	
	defined($class->get_scope_of($name));
}

sub this_contains {
	my $class = shift;
	my ($name) = @_;
	
	return $class->{variables}->{$name};
}

sub get_scope_of {
	my $class = shift;
	my ($name) = @_;
	
	my $scope = $class;
	while(defined($scope)) {
		return $scope if $scope->this_contains($name);
		$scope = $scope->{parent};
	}
	
	undef;
}

sub child {
	my $class = shift;
	
	Scope->new($class);
}


1;
