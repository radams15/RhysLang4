package uk.co.therhys
package node

import lexer.Token

class Function(name: String, params: Array[String], body: AST) extends AST {
  override def toString: String = s"Function()"

  
}
