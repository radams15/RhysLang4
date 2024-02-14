package uk.co.therhys
package node

import lexer.Token

class Return(term: AST) extends AST {
  override def toString: String = s"Return()"
}
