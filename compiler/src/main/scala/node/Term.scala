package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Term(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Term()"

  override def accept(visitor: Visitor): Unit = visitor.visitTerm(this)


   def getLeft: AST = left;

   def getOp: Token = op;

   def getRight: AST = right;



}
