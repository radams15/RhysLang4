package uk.co.therhys
package node

import lexer.Token

class Subtract(left: AST, right: AST) extends AST {
  override def toString: String = s"Subtract()"
}
