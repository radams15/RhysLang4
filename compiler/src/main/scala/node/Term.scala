package uk.co.therhys
package node

import lexer.Token

class Term(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Term()"
}
