package uk.co.therhys
package node

import lexer.Token

class Comparison(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Comparison()"

  
}
