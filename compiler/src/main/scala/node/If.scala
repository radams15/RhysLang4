package uk.co.therhys
package node

import lexer.Token

class If(conditional: AST, ifTrue: AST, ifFalse: AST) extends AST {
  override def toString: String = s"If()"

   def getConditional: AST = conditional;

   def getIfTrue: AST = ifTrue;

   def getIfFalse: AST = ifFalse;



}
