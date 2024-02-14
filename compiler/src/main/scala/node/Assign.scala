package uk.co.therhys
package node

import lexer.Token

class Assign(name: StringLiteral, value: AST) extends AST {
  override def toString: String = s"Assign()"
}
