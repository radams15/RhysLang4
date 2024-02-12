package uk.co.therhys
package node

class Var(name: String, value: AST) extends AST {
  override def equals(other: AST): Boolean = false
}
