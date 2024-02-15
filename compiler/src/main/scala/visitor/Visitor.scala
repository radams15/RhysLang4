package uk.co.therhys
package visitor

import node.*

trait Visitor {

    def visitAssign(assignObj: Assign): Unit

    def visitAsm(asmObj: Asm): Unit

    def visitIndex(indexObj: Index): Unit

    def visitExpression(expressionObj: Expression): Unit

    def visitBlock(blockObj: Block): Unit

    def visitCall(callObj: Call): Unit

    def visitFunction(functionObj: Function): Unit

    def visitGrouping(groupingObj: Grouping): Unit

    def visitId(idObj: Id): Unit

    def visitIf(ifObj: If): Unit

    def visitMy(myObj: My): Unit

    def visitNumberLiteral(numberliteralObj: NumberLiteral): Unit

    def visitEquality(equalityObj: Equality): Unit

    def visitComparison(comparisonObj: Comparison): Unit

    def visitTerm(termObj: Term): Unit

    def visitFactor(factorObj: Factor): Unit

    def visitReturn(returnObj: Return): Unit

    def visitStringLiteral(stringliteralObj: StringLiteral): Unit

    def visitNullLiteral(nullliteralObj: NullLiteral): Unit

    def visitVar(varObj: Var): Unit

    def visitWhile(whileObj: While): Unit

    def visitUnary(unaryObj: Unary): Unit


}
