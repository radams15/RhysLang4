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
  private var inSub: Boolean = false

  private var labelIndex = 0
  private val strings: scala.collection.mutable.Map[String, String] = scala.collection.mutable.Map()
  private def generateLabel(labelType: String): (String, String) = {
    val start = s".${labelType}_$labelIndex"

    labelIndex += 1

    (start, s"${start}_end")
  }

  private def typeof(func: Function): String =
    func.getReturns.getValue match
      case "STRING" | "str" => "STR"
      case "NUMBER" | "int" => "NUM"
      case "void" => "VOID"

  private def typeof(ast: AST): String =
    ast match
      case varType: Var =>
        scope.get(varType.getName.getValue).get
          .getDataType
      case callType: Call =>
        scope.get(callType.getCallee.asInstanceOf[Var].getName.getValue) match
          case Some(variable) => variable.getDataType
          case None | null => error(s"Return type ${callType.getCallee.asInstanceOf[Var].getName.getValue} undefined")
      case numberLiteral: NumberLiteral => "INT"
      case stringLiteral: StringLiteral => "STR"
      case default => error(s"Typeof does apply to: '${ast.getClass.getName}'")

  private def typeof(ast: String): String =
    if(ast.forall(c => c.isDigit)) "INT"
    else "STR"

  private def sizeofType(str: String): Int = 1
  private def sizeof(a: Any): Int = 1


  private def error(str: String) = throw Exception(str)


  override def visitAssign(assignObj: Assign): Unit = {
    assignObj.getValue.accept(this)


    scope.get(assignObj.getName.getValue) match
      case Some(varObj) =>
        varObj match
          case variable: LocalVariable =>
            emit(s"mov(ptr('BP', ${variable.getOffset}), reg('A'))")
          case _ => // Global
            error("Undefined 2")
      case default => error(s"Undefined variable: ${assignObj.getName.getValue}")
  }

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
    val name = functionObj.getName.getValue
    globalScope.set(name, new GlobalVariable(
      dataType = "SUB",
      definition = functionObj
    ))

    if (functionObj.getBody == null)
      return ()

    scope = scope.getNewChild

    emit(s"label('$name')")
    emit("enter()")

    functionObj.getParams.foreach(arg => {
      val size = sizeofType(arg("type").getValue)
      val offset = scope.getStackOffset + 3 // ????
      scope.setNew(arg("name").getValue, new LocalVariable(
        dataType = arg("type").getValue, offset = offset, definition = null
      ))
    })

    inSub = true
    functionObj.getBody.accept(this)
    inSub = false

    emit(s"label('.end_$name')")
    emit("leave()")
    scope = scope.getParent
  }

  override def visitGrouping(groupingObj: Grouping): Unit = ???

  override def visitId(idObj: Id): Unit = ???

  override def visitIf(ifObj: If): Unit = ???

  override def visitMy(myObj: My): Unit = {
    if(inSub) {
      if(myObj.getInitialiser != null)
        myObj.getInitialiser.accept(this)
      else
        emit("mov(reg('A'), 0)")

      emit("op_push(reg('A')")
      val datatype: String = if(myObj.getDatatype != null)
          myObj.getDatatype.getValue
        else if(myObj.getInitialiser != null)
          typeof(myObj.getInitialiser)
        else error("Declarations require either a datatype or initialiser")

      println(s"Define: ${myObj.getName.getValue}")

      scope.setNew(myObj.getName.getValue, new LocalVariable(
        dataType = datatype,
        offset = scope.getStackOffset,
        definition = myObj
      ))

      scope.subStackOffset(sizeofType(datatype))
    } else error("Globals unimplemented") // TODO: global vars
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
    val value = scope.get(name) match
      case Some(value) => value
      case None | null =>
        error(s"Variable ${name} undefined")

    value match
      case localVariable: LocalVariable => emit(s"mov(reg('A'), ptr('BP', ${localVariable.getOffset}))")
      case globalVariable: GlobalVariable =>
        globalVariable.getDataType match
          case "PTR" =>
            emit(s"mov(reg('A'), $name)")
            emit("mov(reg('A'), ptr('A'))")
          case default => emit(s"mov(reg('A'), $name)")
      case default =>
        error(s"Variable ${name} undefined")
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
