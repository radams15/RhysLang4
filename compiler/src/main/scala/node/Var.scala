package uk.co.therhys
package node

import lexer.Token

class Var(name: Token) extends AST {
  override def equals(other: AST): Boolean = false
}
