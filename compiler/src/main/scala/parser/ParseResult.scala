package uk.co.therhys
package parser

class ParseResult[T](value: Option[T], source: Source) {
  def getValue: Option[T] = value
  def getSource: Source = source
}
