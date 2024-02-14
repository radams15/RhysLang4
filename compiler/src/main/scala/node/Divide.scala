package uk.co.therhys
package node

import lexer.Token

class Divide(left: AST, right: AST) extends AST {
  override def toString: String = s"Divide()"
}
