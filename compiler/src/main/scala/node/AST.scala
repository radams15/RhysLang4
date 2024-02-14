package uk.co.therhys
package node

class AST {
  def pprint(i: Int = 0): String = ("\t"*i) + toString
  override def toString: String = "AST()"
}
