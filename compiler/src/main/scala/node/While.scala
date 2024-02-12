package uk.co.therhys
package node

class While(conditional: AST, body: AST) extends AST {
  override def equals(other: AST): Boolean = false
}
