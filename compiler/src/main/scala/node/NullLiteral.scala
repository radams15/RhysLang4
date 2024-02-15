package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class NullLiteral() extends AST {
  override def toString: String = s"NullLiteral()"

  override def accept(visitor: Visitor): Unit = visitor.visitNullLiteral(this)





}
