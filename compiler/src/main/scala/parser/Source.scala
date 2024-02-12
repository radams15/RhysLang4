package uk.co.therhys
package parser

import scala.util.matching.Regex
import scala.util.matching.Regex.Match

class Source(string: String, index: Int) {
  def getString: String = string
  def getIndex: Int = index

  def matches(regex: Regex): ParseResult[String] = {
    val match_ = regex.findFirstMatchIn(string.substring(index))

    match_ match
      case Some(m) =>
        val value = m.group(0)
        val newIndex = index+value.length
        val source = new Source(string, newIndex)
        new ParseResult(value, source)
      case None => null
  }
}
