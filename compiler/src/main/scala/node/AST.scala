package uk.co.therhys
package node

abstract class AST {
  def equals(other: AST): Boolean

  def pprint(i: Int = 0): String = ("\t"*i) + toString
  override def toString: String = "AST()"
}
