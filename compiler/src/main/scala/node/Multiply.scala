package uk.co.therhys
package node

import lexer.Token

class Multiply(left: AST, right: AST) extends AST {
  override def toString: String = s"Multiply()"
}
