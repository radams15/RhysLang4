package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Call(callee: AST, paren: Token, args: Array[AST]) extends AST {
  override def toString: String = s"Call()"

  override def accept(visitor: Visitor): Unit = visitor.visitCall(this)


   def getCallee: AST = callee;

   def getParen: Token = paren;

   def getArgs: Array[AST] = args;



}
