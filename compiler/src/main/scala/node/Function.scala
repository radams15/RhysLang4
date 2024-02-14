package uk.co.therhys
package node

import lexer.Token

class Function(name: StringLiteral, params: Array[StringLiteral], body: AST) extends AST {
  override def toString: String = s"Function()"
}
