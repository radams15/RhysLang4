package uk.co.therhys
package node

import lexer.Token

class Function(name: Token, params: Array[Map[String,Token]], returns: Token, body: Block, arity: Int) extends AST {
  override def toString: String = s"Function()"

   def getName: Token = name;

   def getParams: Array[Map[String,Token]] = params;

   def getReturns: Token = returns;

   def getBody: Block = body;

   def getArity: Int = arity;



}
