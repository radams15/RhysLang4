package uk.co.therhys
package lexer

class Token(
           name: TokenType,
           value: String,
           literal: Option[String],
           line: Int,
           col: Int
         ):
  def getName: TokenType = name
  def getValue: String = value
  def getLiteral: Option[String] = literal
  def getLine: Int = line
  def getCol: Int = col
  override def toString: String = s"Token($name => '$value')"