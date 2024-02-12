package uk.co.therhys
package parser

import scala.util.matching.Regex

class Parser[T](_parse: Source => ParseResult[T]) {
  def parse: Source => ParseResult[T] = _parse
}

object Parser {
  def regexp(regexp: Regex): Parser[String] =
    new Parser(source => source.matches(regexp))

  def hello: Parser[String] = Parser.regexp("hello[0-9]".r)
}