package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Block(statements: Array[AST]) extends AST {
  override def toString: String = s"Block()"

  override def accept(visitor: Visitor): Unit = visitor.visitBlock(this)


   def getStatements: Array[AST] = statements;



}
