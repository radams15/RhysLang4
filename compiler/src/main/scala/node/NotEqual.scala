package uk.co.therhys
package node

import lexer.Token

class NotEqual(left: AST, right: AST) extends AST {
  override def toString: String = s"NotEqual()"
}
