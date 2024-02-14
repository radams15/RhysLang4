package uk.co.therhys
package node

import lexer.Token

class My(name: Token, initialiser: AST, datatype: Token) extends AST {
  override def equals(other: AST): Boolean = false
}
