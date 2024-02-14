package uk.co.therhys
package node

class Block(statements: Array[AST]) extends AST {
  override def equals(other: AST): Boolean = false

  override def toString: StringLiteral = s"Block(${statements.map(s => s.toString).mkString(", ")})"
}
