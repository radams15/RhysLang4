package uk.co.therhys
package node

import lexer.Token

class Index(value: AST, index: AST) extends AST {
  override def toString: String = s"Index()"

   def getValue: AST = value;

   def getIndex: AST = index;



}
