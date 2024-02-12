package uk.co.therhys
package node

class If(conditional: AST, ifTrue: AST, ifFalse: AST) extends AST {
  override def equals(other: AST): Boolean = false
}
