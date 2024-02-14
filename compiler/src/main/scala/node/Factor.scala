package uk.co.therhys
package node

import lexer.Token

class Factor(left: AST, op: Token, right: AST) extends AST {
  override def toString: String = s"Factor()"

  
}
