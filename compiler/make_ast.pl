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
   'name: StringLiteral, value: AST'
 ],
 [
   'Block',
   'AST',
   'statements: Array[AST]'
 ],
 [
   'Call',
   'AST',
   'callee: StringLiteral, args: Array[AST]'
 ],
 [
   'Function',
   'AST',
   'name: StringLiteral, params: Array[StringLiteral], body: AST'
 ],
 [
   'Grouping',
   'AST',
   'expr: AST'
 ],
 [
   'Id',
   'AST',
   'value: StringLiteral'
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
  'Equal',
  'AST',
  'left: AST, right: AST'
 ],
 [
  'NotEqual',
  'AST',
  'left: AST, right: AST'
 ],
 [
  'Add',
  'AST',
  'left: AST, right: AST'
 ],
 [
  'Subtract',
  'AST',
  'left: AST, right: AST'
 ],
 [
  'Multiply',
  'AST',
  'left: AST, right: AST'
 ],
 [
  'Divide',
  'AST',
  'left: AST, right: AST'
 ],
 [
   'Return',
   'AST',
   'term: AST'
 ],
 [
   'StringLiteral',
   'AST',
   'value: StringLiteral'
 ],
 [
   'Var',
   'AST',
   'name: Token'
 ],
 [
   'While',
   'AST',
   'conditional: AST, body: AST'
 ]
);

sub mktemplate {
    my ($name, $child, $params) = @_;

    return <<EOF;
package uk.co.therhys
package node

import lexer.Token

class $name($params) extends $child {
  override def toString: String = s"$name()"
}
EOF
}

for (@defs) {
    my ($name, $child, $params) = @$_;

    my $template = mktemplate($name, $child, $params);

    open FH, '>', "src/main/scala/node/$name.scala";
    print FH $template;
    close FH;
}