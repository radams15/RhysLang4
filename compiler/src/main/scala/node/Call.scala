package uk.co.therhys
package node

class Call(callee: String, args: Array[AST]) extends AST {
  private def getCallee: String = callee
  private def getArgs: Array[AST] = args

  override def equals(other: AST): Boolean = other.isInstanceOf[Call]
    && callee == other.asInstanceOf[Call].getCallee
    && args.length == other.asInstanceOf[Call].getArgs.length
    && args.zipWithIndex.forall((arg, i) =>
      arg.equals(
        other.asInstanceOf[Call]
          .getArgs(i)
      )
    )
}
