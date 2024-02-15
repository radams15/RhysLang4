package uk.co.therhys
package node

import lexer.Token

class Equality(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Equality()"

   def getLeft: AST = left;

   def getOp: Token = op;

   def getRight: AST = right;



}
