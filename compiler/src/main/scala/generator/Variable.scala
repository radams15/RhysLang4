package uk.co.therhys
package generator

import node.AST

enum VariableType {
  case
    LOCAL,
    GLOBAL
}
class Variable(dataType: String, definition: AST) {
  def getDataType: String = dataType
  def getDefinition: AST = definition
}

class LocalVariable(dataType: String, offset: Int, definition: AST) extends Variable(dataType, definition) {
  def getOffset: Int = offset
}

class GlobalVariable(dataType: String, definition: AST) extends Variable(dataType, definition) {

}

