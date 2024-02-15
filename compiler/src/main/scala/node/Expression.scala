package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Expression(expr: AST) extends AST {
  override def toString: String = s"Expression()"

  def accept(visitor: Visitor): Unit = visitor.visitExpression(this)


   def getExpr: AST = expr;



}
