package uk.co.therhys
package generator

import visitor.Visitor

import node.*

class Generator extends Visitor {
  override def visitAssign(assignObj: Assign): Unit = ???

  override def visitAsm(asmObj: Asm): Unit = ???

  override def visitIndex(indexObj: Index): Unit = ???

  override def visitExpression(expressionObj: Expression): Unit = ???

  override def visitBlock(blockObj: Block): Unit = ???

  override def visitCall(callObj: Call): Unit = ???

  override def visitFunction(functionObj: node.Function): Unit = ???

  override def visitGrouping(groupingObj: Grouping): Unit = ???

  override def visitId(idObj: Id): Unit = ???

  override def visitIf(ifObj: If): Unit = ???

  override def visitMy(myObj: My): Unit = ???

  override def visitNumberLiteral(numberliteralObj: NumberLiteral): Unit = ???

  override def visitEquality(equalityObj: Equality): Unit = ???

  override def visitComparison(comparisonObj: Comparison): Unit = ???

  override def visitTerm(termObj: Term): Unit = ???

  override def visitFactor(factorObj: Factor): Unit = ???

  override def visitReturn(returnObj: Return): Unit = ???

  override def visitStringLiteral(stringliteralObj: StringLiteral): Unit = ???

  override def visitVar(varObj: Var): Unit = ???

  override def visitWhile(whileObj: While): Unit = ???

  override def visitUnary(unaryObj: Unary): Unit = ???
}
