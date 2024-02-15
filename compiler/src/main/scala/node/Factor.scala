package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Factor(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Factor()"

  override def accept(visitor: Visitor): Unit = visitor.visitFactor(this)


   def getLeft: AST = left;

   def getOp: Token = op;

   def getRight: AST = right;



}
