package uk.co.therhys

import node.*

object Compiler {
  def main(args: Array[String]): Unit = {
    new Function("factorial", Array("n"), new Block(Array(
      new Var("result", new Number(1)),
      new While(new NotEqual(new Id("n"),
        new Number(1)), new Block(Array(
        new Assign("result", new Multiply(new Id("result"),
          new Id("n"))),
        new Assign("n", new Subtract(new Id("n"),
          new Number(1))),
      ))),
      new Return(new Id("result")),
    )))
  }
}
