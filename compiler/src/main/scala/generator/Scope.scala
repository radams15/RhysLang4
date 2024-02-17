package uk.co.therhys
package generator

class Scope(parent: Scope = null) {
  private val variables: scala.collection.mutable.Map[String, Variable] = scala.collection.mutable.Map()

  private var stackOffset = 0

  def getStackOffset: Int = stackOffset
  def addStackOffset(n: Int): Unit = stackOffset += n
  def subStackOffset(n: Int): Unit = stackOffset -= n

  def debug(): Unit = {
    var scope: Scope = this

    while (scope != null) {
      println(scope.variables)
      scope = scope.getParent
    }
  }

  def get(name: String): Option[Variable] =
    getScopeOf(name) match
      case Some(scope) => scope.variables.get(name)
      case null | None => null

  def setNew(name: String, value: Variable): Unit = variables.addOne(name, value)

  def set(name: String, value: Variable): Unit = getScopeOf(name) match
    case Some(scope) => scope.variables.update(name, value)
    case null | None => setNew(name, value)

  def contains(name: String): Boolean = getScopeOf(name).isDefined

  private def getScopeOf(name: String): Option[Scope] = {
    var scope: Scope = this

    while(scope != null) {
      if(scope.variables.contains(name))
        return Some(scope)
      else
        scope = scope.getParent
    }

    null
  }

  def getNewChild: Scope = new Scope(this)
  def getParent: Scope = parent
}
