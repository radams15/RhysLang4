package uk.co.therhys
package node

import lexer.Token

class Block(statements: Array[AST]) extends AST {
  override def toString: String = s"Block()"
}
