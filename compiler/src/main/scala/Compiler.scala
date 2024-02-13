package uk.co.therhys

import node.*

import uk.co.therhys.lexer.Lexer

object Compiler {
  def main(args: Array[String]): Unit = {
    /*new Function("factorial", Array("n"), new Block(Array(
      new Var("result", new Number(1)),
      new While(new NotEqual(new Id("n"),
        new Number(1)), new Block(Array(
        new Assign("result", new Multiply(new Id("result"),
          new Id("n"))),
        new Assign("n", new Subtract(new Id("n"),
          new Number(1))),
      ))),
      new Return(new Id("result")),
    )))*/

    val inp =
      """|
        |sub main() : void {
        |	puts('Hello, World');
        |	puts('test2');
        |
        |	#my i = getc();
        |	#putc(i);
        |
        |	puti(malloc(100));
        |	puti(malloc(100));
        |	puti(malloc(100));
        |
        |	return 1+1;
        |}
      |""".stripMargin

    println(inp.substring(90))

    val lex = new Lexer(inp)
    println(lex.scanTokens)
  }
}
