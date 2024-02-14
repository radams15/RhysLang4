package uk.co.therhys
package parser

import lexer.{Token, TokenType}
import lexer.TokenType.*
import node.*

import scala.collection.mutable.ListBuffer

class Parser(tokens: Array[Token]) {
  private var current = 0

  def error(err: StringLiteral) = throw Exception(err)

  def peek(inc: Int = 0) = tokens(current + inc)

  def previous: Token = tokens(current - 1)

  def advance: Token = {
    current += 1
    previous
  }

  def atEnd: Boolean = peek().getName == EOF

  def check(expected: TokenType): Boolean = peek().getName == expected

  def consume(expected: TokenType, err: StringLiteral): Token =
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