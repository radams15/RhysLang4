package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class If(conditional: AST, ifTrue: AST, ifFalse: AST) extends AST {
  override def toString: String = s"If()"

  override def accept(visitor: Visitor): Unit = visitor.visitIf(this)


   def getConditional: AST = conditional;

   def getIfTrue: AST = ifTrue;

   def getIfFalse: AST = ifFalse;



}
