package uk.co.therhys

import node.*
import lexer.Lexer
import parser.Parser

import uk.co.therhys.generator.{Generator, PrettyPrinter}

object Compiler {
  def main(args: Array[String]): Unit = {
    val inp =
      """|
      |sub strlen(val: str) : int {
         |    asm('
         |        &mov(reg("A"), ptr("BP", +3));
         |        &mov(reg("A"), ptr("A")); # dereference A (index 0)
         |    ');
         |}
      |sub putc(val: int) : void {
         |    asm('
         |		&mov(reg("A"), ptr("BP", +3)); # a = val
         |		&intr(1);
         |    ');
         |}
         |sub puts(data: str) : void {
         |	my i = 0;
         |	my len = strlen(data);
         |
         |	while(i < len) {
         |		putc(data[i]);
         |		i = i + 1;
         |	}
         |
         |	putc(10); # \n
         |}
        |sub main() : void {
        |	puts('Hello, World');
        |	puts('test2');
        |
        |	my i = getc();
        |	putc(i);
        |
        |	puti(malloc(100));
        |	puti(malloc(100));
        |	puti(malloc(100));
        |
        |	return 1+1;
        |}
        |""".stripMargin

    val lex = new Lexer(inp)
    val parse = new Parser(lex.scanTokens.toArray)
    val objects = parse.parse

    val gen = new Generator()

    objects.accept(gen)
  }
}
