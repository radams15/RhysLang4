package uk.co.therhys
package lexer

class Token(
           name: TokenType,
           value: String,
           literal: Option[String],
           line: Int,
           col: Int
         ):
  override def toString: String = s"Token($name => '$value')"