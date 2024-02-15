package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class StringLiteral(value: String) extends AST {
  override def toString: String = s"StringLiteral()"

  def accept(visitor: Visitor): Unit = visitor.visitStringLiteral(this)


   def getValue: String = value;



}
