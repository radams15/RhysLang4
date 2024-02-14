package uk.co.therhys
package node

import lexer.Token

class While(conditional: AST, body: AST) extends AST {
  override def toString: String = s"While()"

  
}
