package uk.co.therhys
package parser

import lexer.{Token, TokenType}
import lexer.TokenType.*
import node.*

import scala.collection.mutable.ListBuffer

class Parser(tokens: Array[Token]) {
  private var current = 0

  def error(err: String) = throw Exception(err)

  def peek(inc: Int = 0) = tokens(current + inc)

  def previous: Token = tokens(current - 1)

  def advance: Token = {
    current += 1
    previous
  }

  def atEnd: Boolean = peek().getName == EOF

  def check(expected: TokenType): Boolean = peek().getName == expected

  def consume(expected: TokenType, err: String): Token =
    if! check(expected) then
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

  def parse: AST = {
    program
  }

  def program: AST = {
    val out = ListBuffer[AST]()

    while(! atEnd) {
      out ::: declaration
    }

    Block(out.toArray)
  }

  def declaration = if matches(MY)
    then varDeclaration
    else statement

  def varDeclaration = {
    val name = consume(IDENTIFIER, "Variable must have identifier")

    var initialiser: AST = null
    var datatype: Token = null

    if(matches(COLON))
      datatype = consume(IDENTIFIER, "Declarations with ':' must have type")

    if(matches(EQUALS))
      initialiser = expression

    if(datatype == null && initialiser == null)
      error("Declarations require either a type declaration or an intialiser statement")

    consume(SEMICOLON, "Declaration must end with ';'")

    new My(name, initialiser, datatype)
  }


  def equality: AST = {
    var expr = factor

    while (matches(BANG_EQUALS) || matches(EQUALS_EQUALS)) {
      val op = previous
      val right = factor

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

    while(matches(DIVIDE) || matches(MULTIPLY)) {
      val op = previous
      val right = unary

      expr = Factor(expr, op, right)
    }

    expr
  }

  def unary: AST =
    if(matches(BANG) || matches(MINUS)) {
      val op = previous
      val right = unary

      Unary(op, right)
    } else {
      index
    }

  def index: AST = {
    val expr = primary

    if(matches(LEFT_BRACKET)) {
      val indexExpr = expression
      consume(RIGHT_BRACKET, "Index requires closing']'")

      Index(expr, indexExpr)
    }

    expr
  }

  def asm: AST =
    if(matches(ASM)) {
      consume(LEFT_PAREN, "asm must have parentheses")
      val code = expression
      consume(RIGHT_PAREN, "asm must have parentheses")

      Asm(code)
    } else {
      call
    }

  def call = {
    var expr = primary

    while(!matches(LEFT_PAREN)) {
      expr = finishCall(expr)
    }

    expr
  }


  def finishCall(callee: Token) = {
    val arguments: Array[AST] = Array()

    if(! check(RIGHT_PAREN)) {
      while({
        arguments ::: expression
        matches(COMMA)
      }) ()
    }

    val paren = consume(RIGHT_PAREN, "Expect ')' after subroutine call")

    Call(callee, paren, arguments)
  }


  def primary: AST =
    if(matches(FALSE))
    NumberLiteral(0)
    else if(matches(TRUE))
      NumberLiteral(1)
    else if(matches(NULL))
      NullLiteral()
    else if(matches(NUMBER))
      NumberLiteral(Integer.parseInt(previous.getLiteral.get))
    else if(matches(STRING))
      StringLiteral(previous.getLiteral.get)
    else if(matches(IDENTIFIER))
      Var(previous)
    else if(matches(LEFT_PAREN)) {
      val expr = expression
      consume(RIGHT_PAREN, "Expect ')' after expression")
      Grouping(expr)
    } else
      error(s"Unknown primary: $peek")
}