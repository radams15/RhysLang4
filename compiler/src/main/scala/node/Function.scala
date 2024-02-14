package uk.co.therhys
package node

import lexer.Token

class Function(name: Token, params: Array[Map[String, Token]], returns: Token, body: Block, arity: Int) extends AST {
  override def toString: String = s"Function()"

  
}
