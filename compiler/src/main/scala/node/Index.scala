package uk.co.therhys
package node

import lexer.Token

class Index(value: Token, index: AST) extends AST {
  override def toString: String = s"Index()"
}
