#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use Data::Dumper;

my @defs = (
 [
   'Assign',
   'AST',
   'name: Token, value: AST'
 ],
 [
   'Asm',
   'AST',
   'value: AST'
 ],
 [
   'Index',
   'AST',
   'value: AST, index: AST'
 ],
 [
   'Expression',
   'AST',
   'expr: AST'
 ],
 [
   'Block',
   'AST',
   'statements: Array[AST]'
 ],
 [
   'Call',
   'AST',
   'callee: AST, paren: Token, args: Array[AST]'
 ],
 [
   'Function',
   'AST',
   'name: Token, params: Array[Map[String,Token]], returns: Token, body: Block, arity: Int'
 ],
 [
   'Grouping',
   'AST',
   'expr: AST'
 ],
 [
   'Id',
   'AST',
   'value: String'
 ],
 [
   'If',
   'AST',
   'conditional: AST, ifTrue: AST, ifFalse: AST'
 ],
 [
   'My',
   'AST',
   'name: Token, initialiser: AST, datatype: Token'
 ],
 [
   'NumberLiteral',
   'AST',
   'value: Int'
 ],
 [
  'Equality',
  'AST',
  'left: AST, op: Token, right: AST'
 ],
 [
  'Comparison',
  'AST',
  'left: AST, op: Token, right: AST'
 ],
 [
  'Term',
  'AST',
  'left: AST, op: Token, right: AST'
 ],
 [
  'Factor',
  'AST',
  'left: AST, op: Token, right: AST'
 ],
 [
   'Return',
   'AST',
   'term: AST'
 ],
 [
   'StringLiteral',
   'AST',
   'value: String'
 ],
 [
   'Var',
   'AST',
   'name: Token',
<<EOF
def getName: Token = name
EOF
 ],
 [
   'While',
   'AST',
   'conditional: AST, body: AST'
 ],
 [
   'Unary',
   'AST',
   'op: Token, right: AST'
 ]
);

sub mk_nodetemplate {
    my ($name, $child, $params, $extra) = @_;

    my @params = map {[split /\:\s*/, $_]} (split /,\s+/, $params);

    print Dumper @params;

    my $getters = join "\n", map {
    my ($name, $type) = @$_;
<<EOF
   def get@{[ucfirst $name]}: $type = $name;
EOF
    } @params;

    return <<EOF;
package uk.co.therhys
package node

import lexer.Token

class $name($params) extends $child {
  override def toString: String = s"$name()"

$getters

$extra
}
EOF
}

sub mk_visitortemplate {
    my (@names) = @_;

    my $classes = join "\n", map {
    my $name = lc $_;
<<EOF
    def visit$_(${name}Obj: $_): Unit
EOF
    } @names;

    return <<EOF;
package uk.co.therhys
package visitor

import node.*

trait Visitor {

$classes

}
EOF
}

my @names;
for (@defs) {
    my ($name, $child, $params, $extra) = (@$_, '');

    push @names, $name;

    my $node_template = mk_nodetemplate($name, $child, $params, $extra);

    open FH, '>', "src/main/scala/node/$name.scala";
    print FH $node_template;
    close FH;
}

my $visitor = mk_visitortemplate(@names);

open FH, '>', "src/main/scala/visitor/Visitor.scala";
print FH $visitor;
close FH;