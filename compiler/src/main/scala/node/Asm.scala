package uk.co.therhys
package node

import lexer.Token

class Asm(value: Token) extends AST {
  override def toString: String = s"Asm()"
}
