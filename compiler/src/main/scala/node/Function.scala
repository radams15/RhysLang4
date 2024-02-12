package uk.co.therhys
package node

class Function(name: String, params: Array[String], body: AST) extends AST {
  override def equals(other: AST): Boolean = false
}
