package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Equality(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Equality()"

  def accept(visitor: Visitor): Unit = visitor.visitEquality(this)


   def getLeft: AST = left;

   def getOp: Token = op;

   def getRight: AST = right;



}
