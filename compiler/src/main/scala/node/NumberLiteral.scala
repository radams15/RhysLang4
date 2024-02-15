package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class NumberLiteral(value: Int) extends AST {
  override def toString: String = s"NumberLiteral()"

  override def accept(visitor: Visitor): Unit = visitor.visitNumberLiteral(this)


   def getValue: Int = value;



}
