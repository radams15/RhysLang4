package uk.co.therhys
package lexer

import lexer.TokenType._

import scala.collection.mutable.ListBuffer

class Lexer(source: String) {
  private var start = 0
  private var current = 0
  private var line = 1

  private def isAlpha(c: Char): Boolean = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')

  private def isNumeric(c: Char): Boolean = c >= '0' && c <= '9'

  private def isAlphaNumeric(c: Char): Boolean = isAlpha(c) || isNumeric(c)


  private def sourceAt(start: Int, end: Int): String = source.substring(start, end)
  private def sourceAt(start: Int): Char = sourceAt(start, start+1).charAt(0)
  private def peek(inc: Int = 0): Char = sourceAt(current+inc)
  private def advance: Char = {
    current += 1
    sourceAt(current)
  }

  private def atEnd: Boolean = current >= source.length
  private def matches(expected: Char): Boolean = {
    if(atEnd || sourceAt(current) != expected) {
      return false
    }

    advance
    true
  }

  private def addToken(tokenType: TokenType, literal: Option[String]=null): Token =
      new Token(tokenType, sourceAt(start, current), literal, line, start)

  private def string(strChar: Char): Token = {
    while(peek() != strChar && !atEnd) {
      if(peek() == '\n')
        line += 1

      advance
    }

    advance

    addToken(STRING, Some(sourceAt(start+1, current-1)))
  }

  private def number(): Token = {
    while(isNumeric(peek()))
      advance

    if(peek() == '.' && isNumeric(peek(1))) {
      advance

      while (peek().isDigit)
        advance
    }

    addToken(NUMBER, Some(sourceAt(start, current)))
  }

  private def identifier(): Token = {
    while (peek() == '_' || isAlphaNumeric(peek()))
      advance

    val value = sourceAt(start, current)

    // TODO: check if value is a keyword

    addToken(IDENTIFIER, Some(value))
  }


  private def scanToken: Token = {
    val c = advance

    c match {
      case '(' => addToken(LEFT_PAREN)
      case ')' => addToken(RIGHT_PAREN)
      case '{' => addToken(LEFT_BRACE)
      case '}' => addToken(RIGHT_BRACE)
      case '[' => addToken(LEFT_BRACKET)
      case ']' => addToken(RIGHT_BRACKET)
      case ',' => addToken(COMMA)
      case '.' => addToken(DOT)
      case '-' => addToken(MINUS)
      case '+' => addToken(PLUS)
      case '*' => addToken(MULTIPLY)
      case '/' => addToken(DIVIDE)
      case ';' => addToken(SEMICOLON)
      case ':' => addToken(COLON)

      case '#' =>
        while(peek() != '\n' && ! atEnd)
          advance
        null

      case '!' => addToken(if matches('=') then BANG_EQUALS else BANG)
      case '=' => addToken(if matches('=') then EQUALS_EQUALS else EQUALS)
      case '<' => addToken(if matches('=') then LESS_EQUALS else LESS)
      case '>' => addToken(if matches('=') then GREATER_EQUALS else GREATER)

      case '\'' | '"' => string(c)

      case '\n' =>
        line += 1
        null

      case ' ' | '\t' | '\r' => null

      case _ =>
        if(isNumeric(c))
          number()
        else if(c == '_' || isAlpha(c))
          identifier()
        else
          throw RuntimeException("Invalid token: " + c)
    }
  }

  def scanTokens: List[Token] = {
    val tokens: ListBuffer[Token] = ListBuffer()

    while(! atEnd) {
      start = current
      val tok = scanToken
      if(tok != null) {
        println(tok)
        tokens.addOne(tok)
      }
    }

    tokens.addOne(addToken(EOF))

    tokens.toList
  }

}
