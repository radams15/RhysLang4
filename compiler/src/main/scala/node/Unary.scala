package uk.co.therhys
package node

import lexer.Token

class Unary(op: Token, right: AST) extends AST {
  override def toString: String = s"Unary()"
}
