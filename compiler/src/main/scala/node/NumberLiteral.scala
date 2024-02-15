package uk.co.therhys
package node

import lexer.Token

class NumberLiteral(value: Int) extends AST {
  override def toString: String = s"NumberLiteral()"

   def getValue: Int = value;



}
