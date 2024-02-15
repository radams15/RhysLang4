package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Comparison(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Comparison()"

  override def accept(visitor: Visitor): Unit = visitor.visitComparison(this)


   def getLeft: AST = left;

   def getOp: Token = op;

   def getRight: AST = right;



}
