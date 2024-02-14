package uk.co.therhys
package node

import lexer.Token

class Add(left: AST, right: AST) extends AST {
  override def toString: String = s"Add()"
}
