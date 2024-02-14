package uk.co.therhys
package node

import lexer.Token

class If(conditional: AST, ifTrue: AST, ifFalse: AST) extends AST {
  override def toString: String = s"If()"
}
