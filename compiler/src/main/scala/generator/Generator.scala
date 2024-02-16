package uk.co.therhys
package generator

import visitor.Visitor
import node.*
import lexer.TokenType.{EQUALS, GREATER, LESS}

import uk.co.therhys.lexer.TokenType

class Generator extends Visitor {
  private def emit(str: String): Unit = println(str)
  private val globalScope = new Scope()
  private var scope = globalScope

  private var labelIndex = 0
  private var strings: scala.collection.mutable.Map[String, String] = scala.collection.mutable.Map()
  private def generateLabel(labelType: String): (String, String) = {
    val start = s".${labelType}_$labelIndex"

    labelIndex += 1

    (start, s"${start}_end")
  }

  private def error(str: String) = throw Exception(str)


  override def visitAssign(assignObj: Assign): Unit = ???

  override def visitAsm(asmObj: Asm): Unit = {
    emit(asmObj.getValue.getLiteral.get)
  }

  override def visitIndex(indexObj: Index): Unit = ???

  override def visitExpression(expressionObj: Expression): Unit = {
    expressionObj.getExpr
      .accept(this)
  }

  override def visitBlock(blockObj: Block): Unit = {
    blockObj.getStatements
      .foreach { s => s.accept(this) }
  }

  override def visitCall(callObj: Call): Unit = {
    callObj.getArgs.foreach(arg => {
      arg.accept(this)
      emit("op_push(reg 'A')")
    })

    callObj.getCallee.accept(this)
    emit("op_call(reg 'A')")

    Range(1, callObj.getArgs.length)
      .foreach(_ => emit("op_pop(reg 'tmp')"))
  }

  override def visitFunction(functionObj: node.Function): Unit = {
    functionObj.getBody.accept(this)
  }

  override def visitGrouping(groupingObj: Grouping): Unit = ???

  override def visitId(idObj: Id): Unit = ???

  override def visitIf(ifObj: If): Unit = ???

  override def visitMy(myObj: My): Unit = {
    myObj.getInitialiser.accept(this)
  }

  override def visitNumberLiteral(numberliteralObj: NumberLiteral): Unit = {
    val value = numberliteralObj.getValue
    emit(s"mov(reg('A'), ${value})")
  }

  override def visitEquality(equalityObj: Equality): Unit = ???

  private def cmp(a: String, b: String, op: TokenType, inv: Boolean): Unit = {
    val (start, end) = generateLabel("cmp")

    emit(s"comp($a, $b)")

    emit(op match
      case LESS => s"brlz('$start')"
      case GREATER => s"brgbz('$start')"
      case EQUALS => s"brz('$start')"
      case default => error(s"Unknown op: $op")
    )

    emit(s"mov($a, 0)")
    emit(s"br('$end')")
    emit(s"label('$start')")
    emit(s"mov($a, 1)")

    emit(s"label('$end')")

    if(inv)
      emit(s"op_not($a, $a)")
  }

  override def visitComparison(comparisonObj: Comparison): Unit = {
    comparisonObj.getOp.getName match
      case LESS | GREATER => {
        comparisonObj.getRight.accept(this)
        emit("op_push(reg('A'))")
        comparisonObj.getLeft.accept(this)
        emit("op_pop(reg('C'))")

        cmp("reg('A')", "reg('C')", comparisonObj.getOp.getName, false)
      }

      case default => error(s"Unknown term: ${comparisonObj.getOp.getName}")
  }

  override def visitTerm(termObj: Term): Unit = {
    termObj.getLeft.accept(this)
    termObj.getRight.accept(this)
  }

  override def visitFactor(factorObj: Factor): Unit = ???

  override def visitReturn(returnObj: Return): Unit = {
    returnObj.getTerm.accept(this)
  }

  private def getStringRef(value: String, id: Option[String] = null): String = {
    val stringId = id match
      case Some(value) => value
      case None | null => s"str_${strings.size+1}"

    // TODO: escape characters

    strings.addOne(stringId, value)

    stringId
  }

  override def visitStringLiteral(stringliteralObj: StringLiteral): Unit = {
    val ref = getStringRef(stringliteralObj.getValue)

    emit(s"mov(reg('A'), ${ref})")
  }

  override def visitVar(varObj: Var): Unit = {
    val name = varObj.getName.getValue
    emit(s"# Get $name")
  }

  override def visitWhile(whileObj: While): Unit = {
    val (start, end) = generateLabel("loop")

    emit(s"label('$start')")
    whileObj.getConditional.accept(this)

    emit("comp(reg('A'), 0)")
    emit(s"brz('$end')")

    whileObj.getBody.accept(this)

    emit(s"br('$start')'")

    emit(s"label('$end')")
  }

  override def visitUnary(unaryObj: Unary): Unit = ???

  override def visitNullLiteral(nullliteralObj: NullLiteral): Unit = ???
}
