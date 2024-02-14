package uk.co.therhys
package node

import lexer.Token

class Id(value: String) extends AST {
  override def toString: String = s"Id()"
}
