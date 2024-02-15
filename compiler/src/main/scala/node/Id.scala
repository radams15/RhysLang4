package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Id(value: String) extends AST {
  override def toString: String = s"Id()"

  def accept(visitor: Visitor): Unit = visitor.visitId(this)


   def getValue: String = value;



}
