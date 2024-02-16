package uk.co.therhys
package generator

class Scope(parent: Scope = null) {
  private val variables: scala.collection.mutable.Map[String, String] = scala.collection.mutable.Map()

  private var stackOffset = 0

  def getStackOffset: Int = stackOffset
  def addStackOffset(n: Int): Unit = stackOffset += n
  def subStackOffset(n: Int): Unit = stackOffset -= n

  def get(name: String): Option[String] = {
    getScopeOf(name) match
      case Some(value) => value.get(name)
      case null | None => null
  }

  def setNew(name: String, value: String): Unit = variables.addOne(name, value)
  def set(name: String, value: String): Unit = getScopeOf(name) match
    case Some(scope) => scope.variables.update(name, value)
    case null | None => setNew(name, value)

  def contains(name: String): Boolean = getScopeOf(name).isDefined

  def getScopeOf(name: String): Option[Scope] = {
    var scope: Scope = this

    while(scope != null) {
      variables.get(name) match
        case Some(value) => return Some(scope)
        case null | None => scope = scope.getParent
    }

    null
  }

  def child: Scope = new Scope(this)
  def getParent: Scope = parent
}
