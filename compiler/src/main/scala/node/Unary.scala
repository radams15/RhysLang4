package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Unary(op: Token, right: AST) extends AST {
  override def toString: String = s"Unary()"

  def accept(visitor: Visitor): Unit = visitor.visitUnary(this)


   def getOp: Token = op;

   def getRight: AST = right;



}
