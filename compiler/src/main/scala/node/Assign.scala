package uk.co.therhys
package node

import lexer.Token

class Assign(name: String, value: AST) extends AST {
  override def toString: String = s"Assign()"
}
