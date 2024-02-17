package uk.co.therhys
package parser

import lexer.{Token, TokenType}
import lexer.TokenType.*
import node.*

import scala.collection.mutable.ListBuffer

class Parser(tokens: Array[Token]) {
  private var current = 0

  private def error(err: String) = throw Exception(s"Error at line ${peek().getLine}:${peek().getCol} (${peek()}) => $err")

  private def peek(inc: Int = 0): Token = tokens(current + inc)

  private def previous: Token = tokens(current - 1)

  private def advance: Token = {
    current += 1
    previous
  }

  def atEnd: Boolean = peek().getName == EOF

  def check(expected: TokenType): Boolean = peek().getName == expected

  def consume(expected: TokenType, err: String): Token =
    if !check(expected) then
      error(s"$err at $previous")
    else
      advance

  def matches(expected: TokenType): Boolean =
    if (check(expected)) {
      advance
      true
    } else {
      false
    }

  def parse: Block = {
    program
  }

  def program: Block = {
    val out = ListBuffer[AST]()

    while (!atEnd) {
      out.addOne(declaration)
    }

    Block(out.toArray)
  }

  def declaration: AST = if matches(MY)
  then varDeclaration
  else statement

  private def statement: AST =
    if (matches(IF)) ifStmt
    else if (matches(WHILE)) whileStmt
    else if (matches(SUB)) subDef
    else if (matches(RETURN)) returnStmt
    else if (matches(LEFT_BRACE)) block
    else expressionStatement

  private def expressionStatement: AST = {
    val expr = expression

    consume(SEMICOLON, "Expressions must end with ';'")

    Expression(expr)
  }

  private def returnStmt: Return = {
    val value =
      if check(SEMICOLON) then null
      else expression

    consume(SEMICOLON, "Expected ';'")

    Return(value)
  }

  private def ifStmt: If = {
    consume(LEFT_PAREN, "Expected '(")
    val expr = expression
    consume(RIGHT_PAREN, "Expected ')")

    val trueBranch = statement

    val falseBranch =
      if matches(ELSE) then statement
      else null

    If(expr, trueBranch, falseBranch)
  }

  private def whileStmt: While = {
    consume(LEFT_PAREN, "Expected '(")
    val expr = expression
    consume(RIGHT_PAREN, "Expected ')")

    val body = statement

    While(expr, body)
  }

  private def block: Block = {
    val statements: ListBuffer[AST] = ListBuffer()

    while (!check(RIGHT_BRACE) && !atEnd) {
      statements.addOne(declaration)
    }

    consume(RIGHT_BRACE, "Expected '}")

    Block(statements.toArray)
  }

  private def subDef: Function = {
    val name = consume(IDENTIFIER, "Subroutine requires name")
    consume(LEFT_PAREN, "Subroutine requries '('")

    val params: ListBuffer[Map[String, Token]] = ListBuffer()

    if (!check(RIGHT_PAREN)) {
      while {
        val name = consume(IDENTIFIER, "Subroutine declaration requires parameters")
        consume(COLON, "Subroutine parameter requires type")
        val varType = consume(IDENTIFIER, "Subroutine parameter requires type")

        params.addOne(Map("name" -> name, "type" -> varType))

        matches(COMMA)
      } do ()
    }

    consume(RIGHT_PAREN, "Subroutine requires ')' after param list")
    consume(COLON, "Expected ';'")
    val returnType = consume(IDENTIFIER, "Subroutine requires type after param list")

    val subBlock: Block = if check(LEFT_BRACE) then {
      consume(LEFT_BRACE, "")
      block
    } else {
      consume(SEMICOLON, "Expected ';' or '{'")
      null
    }

    node.Function(name, params.toArray, returnType, subBlock, params.length)
  }

  private def varDeclaration: My = {
    val name = consume(IDENTIFIER, "Variable must have identifier")

    var initialiser: AST = null
    var datatype: Token = null

    if (matches(COLON))
      datatype = consume(IDENTIFIER, "Declarations with ':' must have type")

    if (matches(EQUALS))
      initialiser = expression

    if (datatype == null && initialiser == null)
      error("Declarations require either a type declaration or an intialiser statement")

    consume(SEMICOLON, "Declaration must end with ';'")

    new My(name, initialiser, datatype)
  }

  private def expression: AST = assignment

  private def assignment: AST = {
    val expr = equality

    if (matches(EQUALS)) {
      val value = assignment

      expr match
        case name: Var =>
          Assign(name.getName, value)
        case _ =>
          error("Invalid assignment target")
    } else {
      expr
    }
  }

  def equality: AST = {
    var expr = comparison

    while (matches(BANG_EQUALS) || matches(EQUALS_EQUALS)) {
      val op = previous
      val right = comparison

      expr = Equality(expr, op, right)
    }

    expr
  }


  def comparison: AST = {
    var expr = term

    while (matches(GREATER) || matches(GREATER_EQUALS) || matches(LESS) || matches(LESS_EQUALS)) {
      val op = previous
      val right = term

      expr = Comparison(expr, op, right)
    }

    expr
  }

  def term: AST = {
    var expr = factor

    while (matches(MINUS) || matches(PLUS)) {
      val op = previous
      val right = factor

      expr = Term(expr, op, right)
    }

    expr
  }

  def factor: AST = {
    var expr = unary

    while (matches(DIVIDE) || matches(MULTIPLY)) {
      val op = previous
      val right = unary

      expr = Factor(expr, op, right)
    }

    expr
  }

  def unary: AST =
    if (matches(BANG) || matches(MINUS)) {
      val op = previous
      val right = unary

      Unary(op, right)
    } else {
      index
    }

  def index: AST = {
    val expr = asm

    if (matches(LEFT_BRACKET)) {
      val indexExpr = expression
      consume(RIGHT_BRACKET, "Index requires closing']'")

      Index(expr, indexExpr)
    }

    expr
  }

  def asm: AST =
    if (matches(ASM)) {
      consume(LEFT_PAREN, "asm must have parentheses")
      val code = consume(STRING, "asm requires a string")
      consume(RIGHT_PAREN, "asm must have parentheses")

      Asm(code)
    } else {
      call
    }

  def call = {
    var expr = primary

    while (matches(LEFT_PAREN)) {
      expr = finishCall(expr)
    }

    expr
  }


  def finishCall(callee: AST) = {
    val arguments: ListBuffer[AST] = ListBuffer()

    if (!check(RIGHT_PAREN)) {
      while ( {
        arguments.addOne(expression)
        matches(COMMA)
      }) ()
    }

    val paren = consume(RIGHT_PAREN, "Expect ')' after subroutine call")

    Call(callee, paren, arguments.toArray)
  }


  def primary: AST =
    if (matches(FALSE))
      NumberLiteral(0)
    else if (matches(TRUE))
      NumberLiteral(1)
    else if (matches(NULL))
      NullLiteral()
    else if (matches(NUMBER))
      NumberLiteral(Integer.parseInt(previous.getLiteral.get))
    else if (matches(STRING))
      StringLiteral(previous.getLiteral.get)
    else if (matches(IDENTIFIER))
      Var(previous)
    else if (matches(LEFT_PAREN)) {
      val expr = expression
      consume(RIGHT_PAREN, "Expect ')' after expression")
      Grouping(expr)
    } else
      error(s"Unknown primary: $peek")
}