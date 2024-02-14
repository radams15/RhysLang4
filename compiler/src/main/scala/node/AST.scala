package uk.co.therhys
package node

abstract class AST {
  def equals(other: AST): Boolean

  def pprint(i: Int = 0): StringLiteral = ("\t"*i) + toString
  override def toString: StringLiteral = "AST()"
}
