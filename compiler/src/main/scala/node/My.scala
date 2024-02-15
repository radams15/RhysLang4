package uk.co.therhys
package node

import lexer.Token

class My(name: Token, initialiser: AST, datatype: Token) extends AST {
  override def toString: String = s"My()"

   def getName: Token = name;

   def getInitialiser: AST = initialiser;

   def getDatatype: Token = datatype;



}
