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
   'name: String, params: Array[Map[String, Token]], returns: Token, body: Block, arity: Int'
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

sub mktemplate {
    my ($name, $child, $params, $extra) = @_;

    return <<EOF;
package uk.co.therhys
package node

import lexer.Token

class $name($params) extends $child {
  override def toString: String = s"$name()"

  $extra
}
EOF
}

for (@defs) {
    my ($name, $child, $params, $extra) = (@$_, '');

    my $template = mktemplate($name, $child, $params, $extra);

    open FH, '>', "src/main/scala/node/$name.scala";
    print FH $template;
    close FH;
}