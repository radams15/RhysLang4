package uk.co.therhys
package node

class Not(value: Int) extends AST {
  override def equals(other: AST): Boolean = false
}

class Equal(left: AST, right: AST) extends AST {
  override def equals(other: AST): Boolean = false
}

class NotEqual(left: AST, right: AST) extends AST {
  override def equals(other: AST): Boolean = false
}

class Add(left: AST, right: AST) extends AST {
  override def equals(other: AST): Boolean = false
}

class Subtract(left: AST, right: AST) extends AST {
  override def equals(other: AST): Boolean = false
}

class Multiply(left: AST, right: AST) extends AST {
  override def equals(other: AST): Boolean = false
}

class Divide(left: AST, right: AST) extends AST {
  override def equals(other: AST): Boolean = false
}