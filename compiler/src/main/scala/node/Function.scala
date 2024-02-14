package uk.co.therhys
package node

class Function(name: StringLiteral, params: Array[StringLiteral], body: AST) extends AST {
  override def equals(other: AST): Boolean = false
}
