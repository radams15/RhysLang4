package uk.co.therhys
package node

import lexer.Token

class Equal(left: AST, right: AST) extends AST {
  override def toString: String = s"Equal()"
}
