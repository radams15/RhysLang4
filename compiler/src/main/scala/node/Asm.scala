package uk.co.therhys
package node

import lexer.Token

class Asm(value: AST) extends AST {
  override def toString: String = s"Asm()"

   def getValue: AST = value;



}
