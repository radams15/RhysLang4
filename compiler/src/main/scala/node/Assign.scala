package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Assign(name: Token, value: AST) extends AST {
  override def toString: String = s"Assign()"

  def accept(visitor: Visitor): Unit = visitor.visitAssign(this)


   def getName: Token = name;

   def getValue: AST = value;



}
