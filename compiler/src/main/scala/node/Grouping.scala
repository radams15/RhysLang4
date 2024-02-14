package uk.co.therhys
package node

import lexer.Token

class Grouping(expr: AST) extends AST {
  override def equals(other: AST): Boolean = false
}
