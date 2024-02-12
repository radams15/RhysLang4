package uk.co.therhys
package parser

class ParseResult[T](value: T, source: Source) {
  def getValue: T = value
  def getSource: Source = source
}
