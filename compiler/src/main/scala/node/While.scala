package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class While(conditional: AST, body: AST) extends AST {
  override def toString: String = s"While()"

  def accept(visitor: Visitor): Unit = visitor.visitWhile(this)


   def getConditional: AST = conditional;

   def getBody: AST = body;



}
