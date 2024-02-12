package uk.co.therhys
package parser

import scala.collection.mutable.ListBuffer
import scala.reflect.ClassTag
import scala.util.matching.Regex

import node.*

class Parser[T](_parse: Source => ParseResult[T]) {
  val parse: Source => ParseResult[T] = _parse

  def or(parser: Parser[T]): Parser[T] =
    new Parser(source => {
      val res = parse(source)

      res match
        case res if res != null => res
        case null => parser.parse(source)
    })

  def bind[U](callback: T => Parser[U]): Parser[U] =
    new Parser(source => {
      val res = parse(source)
      res match {
        case res if res != null =>
          res.getValue match {
            case Some(n) => callback(n).parse(source)
            case null | None => throw Exception("Undefined in bind")
          }
        case null => null
      }
    })

  def and[U](parser: Parser[U]): Parser[U] =
    bind(_ => parser)

  def map[U](callback: T => U): Parser[U] =
    bind(value =>
      Parser.constant(Some(callback(value)))
    )

  def parseStringToCompletion(string: String): Option[T] = {
    val source = new Source(string, 0)
    val res = parse(source)

    res match {
      case res if res != null =>
        val index = res.getSource.getIndex
        if (index != res.getSource.getString.length)
          throw Error("Parse error at index " + index)
        res.getValue

      case null =>
        throw Error("Parse error @ index 1")
    }
  }
}

object Parser {
  def regexp(regexp: Regex): Parser[String] =
    new Parser(source => source.matches(regexp))

  def constant[U](value: Option[U]): Parser[U] =
    new Parser(source => new ParseResult(value, source))

  def error[U](message: String): Parser[U] =
    new Parser(source => {
      throw Error(message)
    })

  def zeroOrMore[U:ClassTag](parser: Parser[U]): Parser[Array[U]] =
    new Parser(source => {
      var src = source
      val results: List[U] = List()
      var item: ParseResult[U] = parser.parse(source)

      while(item != null) {
        src = item.getSource

        results ::: List(item.getValue)

        item = parser.parse(source)
      }

      new ParseResult(Some(results.toArray), source)
    })

  def maybe[U](parser: Parser[U]): Parser[U] =
    parser.or(constant(null))

  val token: Regex => Parser[String] =
    pattern => {
      regexp(pattern)
        .bind(value =>
          ignored.and(constant(Some(value))))
    }

  val whitespace = regexp("[ \n\r\t]+".r)
  val comments = regexp("//.*".r)
  val ignored = zeroOrMore(whitespace.or(comments))

  val FUNCTION = token("function\b".r)
  val IF = token("if\b".r)
  val ELSE = token("else\b".r)
  val RETURN = token("return\b".r)
  val VAR = token("var\b".r)
  val WHILE = token("while\b".r)

  val COMMA = token(",".r)
  val SEMICOLON = token(";".r)
  val LEFT_PAREN = token("\\(".r)
  val RIGHT_PAREN = token("\\)".r)
  val LEFT_BRACE = token("\\[".r)
  val RIGHT_BRACE = token("]".r)

  val NUMBER = token("[0-9]+".r)
    .map(digits => new Number(Integer.parseInt(digits)))

  val ID = token("[a-zA-Z_][a-zA-Z0-9_]*".r)

  val id = ID.map(x => new Id(x))

  val NOT = token("!".r).map(_ => classOf[Not])
  val EQUAL = token("==".r).map(_ => classOf[Equal])
  val NOT_EQUAL = token("!=".r).map(_ => classOf[NotEqual])
  val PLUS = token("\\+".r).map(_ => classOf[Add])
  val MINUS = token("-".r).map(_ => classOf[Subtract])
  val STAR = token("\\*".r).map(_ => classOf[Multiply])
  val SLASH = token("/".r).map(_ => classOf[Divide])
}