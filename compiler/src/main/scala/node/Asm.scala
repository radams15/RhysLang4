package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Asm(value: AST) extends AST {
  override def toString: String = s"Asm()"

  override def accept(visitor: Visitor): Unit = visitor.visitAsm(this)


   def getValue: AST = value;



}
