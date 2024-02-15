package uk.co.therhys
package node

import visitor.Visitor

abstract class AST {
  def pprint(i: Int = 0): String = ("\t"*i) + toString
  override def toString: String = "AST()"
  def accept(visitor: Visitor): Unit
}
