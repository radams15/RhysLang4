package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Var(name: Token) extends AST {
  override def toString: String = s"Var()"

  def accept(visitor: Visitor): Unit = visitor.visitVar(this)


   def getName: Token = name;



}
