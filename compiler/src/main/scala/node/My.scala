package uk.co.therhys
package node

import lexer.Token
import visitor.Visitor

class My(name: Token, initialiser: AST, datatype: Token) extends AST {
  override def toString: String = s"My()"

  override def accept(visitor: Visitor): Unit = visitor.visitMy(this)


   def getName: Token = name;

   def getInitialiser: AST = initialiser;

   def getDatatype: Token = datatype;



}
