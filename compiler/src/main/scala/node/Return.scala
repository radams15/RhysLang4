package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Return(term: AST) extends AST {
  override def toString: String = s"Return()"

  def accept(visitor: Visitor): Unit = visitor.visitReturn(this)


   def getTerm: AST = term;



}
