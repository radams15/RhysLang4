package uk.co.therhys
package node

import lexer.Token

class Call(callee: StringLiteral, args: Array[AST]) extends AST {
  override def toString: String = s"Call()"
}
