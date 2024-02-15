package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Grouping(expr: AST) extends AST {
  override def toString: String = s"Grouping()"

  def accept(visitor: Visitor): Unit = visitor.visitGrouping(this)


   def getExpr: AST = expr;



}
