package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class Index(value: AST, index: AST) extends AST {
  override def toString: String = s"Index()"

  def accept(visitor: Visitor): Unit = visitor.visitIndex(this)


   def getValue: AST = value;

   def getIndex: AST = index;



}
