package uk.co.therhys
package node

import lexer.Token

class Assign(name: Token, value: AST) extends AST {
  override def toString: String = s"Assign()"

   def getName: Token = name;

   def getValue: AST = value;



}
