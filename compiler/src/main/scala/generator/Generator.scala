package uk.co.therhys
package generator

import visitor.Visitor

import node.*

class Generator extends Visitor {
  override def visitAssign(assignObj: Assign): Unit = {

  }

  override def visitAsm(asmObj: Asm): Unit = {

  }

  override def visitIndex(indexObj: Index): Unit = {

  }

  override def visitExpression(expressionObj: Expression): Unit = {
    expressionObj.getExpr.accept(this)
  }

  override def visitBlock(blockObj: Block): Unit = {
    blockObj.getStatements.foreach(s => s.accept(this))
  }

  override def visitCall(callObj: Call): Unit = {
    callObj.getCallee.accept(this)
    callObj.getArgs.foreach(arg => arg.accept(this))
  }

  override def visitFunction(functionObj: node.Function): Unit = {
    functionObj.getBody.accept(this)
  }

  override def visitGrouping(groupingObj: Grouping): Unit = {

  }

  override def visitId(idObj: Id): Unit = {

  }

  override def visitIf(ifObj: If): Unit = {

  }

  override def visitMy(myObj: My): Unit = {
    myObj.getInitialiser.accept(this)
  }

  override def visitNumberLiteral(numberliteralObj: NumberLiteral): Unit = {

  }

  override def visitEquality(equalityObj: Equality): Unit = {

  }

  override def visitComparison(comparisonObj: Comparison): Unit = {

  }

  override def visitTerm(termObj: Term): Unit = {
    termObj.getLeft.accept(this)
    termObj.getRight.accept(this)
  }

  override def visitFactor(factorObj: Factor): Unit = {

  }

  override def visitReturn(returnObj: Return): Unit = {
    returnObj.getTerm.accept(this)
  }

  override def visitStringLiteral(stringliteralObj: StringLiteral): Unit = {

  }

  override def visitVar(varObj: Var): Unit = {

  }

  override def visitWhile(whileObj: While): Unit = {

  }

  override def visitUnary(unaryObj: Unary): Unit = {

  }

  override def visitNullLiteral(nullliteralObj: NullLiteral): Unit = {

  }
}
