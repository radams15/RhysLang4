package uk.co.therhys
package node

import lexer.Token

class StringLiteral(value: String) extends AST {
  override def toString: String = s"StringLiteral()"
}
