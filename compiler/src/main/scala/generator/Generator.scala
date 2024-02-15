package uk.co.therhys
package generator

import visitor.Visitor

import node.*

class Generator extends Visitor {
  private var level = 0;
  private def pprint(str: String) = println(("\t"*level) + str)


  override def visitAssign(assignObj: Assign): Unit = ???

  override def visitAsm(asmObj: Asm): Unit = ???

  override def visitIndex(indexObj: Index): Unit = ???

  override def visitExpression(expressionObj: Expression): Unit = {
    pprint("Expression")
    level += 1
    expressionObj.getExpr.accept(this)
    level -= 1
  }

  override def visitBlock(blockObj: Block): Unit = {
    pprint("Block")
    level += 1
    blockObj.getStatements.foreach(s => s.accept(this))
    level -= 1
  }

  override def visitCall(callObj: Call): Unit = {
    pprint("Call")
    level += 1
    callObj.getCallee.accept(this)
    callObj.getArgs.foreach(arg => arg.accept(this))
    level -= 1
  }

  override def visitFunction(functionObj: node.Function): Unit = {
    pprint("Function " + functionObj.getName)
    level += 1

    functionObj.getBody.accept(this)

    level -= 1
  }

  override def visitGrouping(groupingObj: Grouping): Unit = ???

  override def visitId(idObj: Id): Unit = ???

  override def visitIf(ifObj: If): Unit = ???

  override def visitMy(myObj: My): Unit = {
    pprint("My " + myObj.getName + " of type " + myObj.getDatatype)
    level += 1

    myObj.getInitialiser.accept(this)

    level -= 1
  }

  override def visitNumberLiteral(numberliteralObj: NumberLiteral): Unit = {
    pprint("Number " + numberliteralObj.getValue)
  }

  override def visitEquality(equalityObj: Equality): Unit = ???

  override def visitComparison(comparisonObj: Comparison): Unit = ???

  override def visitTerm(termObj: Term): Unit = {
    pprint("Term " + termObj.getOp)
    level += 1

    termObj.getLeft.accept(this)
    termObj.getRight.accept(this)

    level -= 1
  }

  override def visitFactor(factorObj: Factor): Unit = ???

  override def visitReturn(returnObj: Return): Unit = {
    pprint("Return")
    level += 1

    returnObj.getTerm.accept(this)

    level -= 1
  }

  override def visitStringLiteral(stringliteralObj: StringLiteral): Unit = {
    pprint("String '" + stringliteralObj.getValue + "'")
  }

  override def visitVar(varObj: Var): Unit = {
    pprint("Var " + varObj.getName)
  }

  override def visitWhile(whileObj: While): Unit = ???

  override def visitUnary(unaryObj: Unary): Unit = ???

  override def visitNullLiteral(nullliteralObj: NullLiteral): Unit = ???
}
