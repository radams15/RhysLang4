package uk.co.therhys
package node

import lexer.Token

class Id(value: StringLiteral) extends AST {
  override def toString: String = s"Id()"
}
