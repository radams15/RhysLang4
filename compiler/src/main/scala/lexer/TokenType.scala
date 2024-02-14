package uk.co.therhys
package lexer

enum TokenType {
  case
  LEFT_PAREN,
  RIGHT_PAREN,
  LEFT_BRACE,
  RIGHT_BRACE,
  LEFT_BRACKET,
  RIGHT_BRACKET,
  COMMA,
  DOT,
  MINUS,
  PLUS,
  MULTIPLY,
  DIVIDE,
  SEMICOLON,
  COLON,
  BANG_EQUALS,
  BANG,
  EQUALS_EQUALS,
  EQUALS,
  LESS_EQUALS,
  LESS,
  GREATER_EQUALS,
  GREATER,

  STRING,
  NUMBER,
  IDENTIFIER,
  EOF,

  MY,
  FOR,
  WHILE,
  IF,
  ELSE,
  SUB,
  OR,
  AND,
  NOT,
  RETURN,
  ASM,
  STATIC,
  STRUCT,
  SIZEOF,
  ALLOC,
  FALSE,
  TRUE,
  NULL
}

val keywords = Map(
  "MY" -> TokenType.MY,
  "FOR" -> TokenType.FOR,
  "WHILE" -> TokenType.WHILE,
  "IF" -> TokenType.IF,
  "ELSE" -> TokenType.ELSE,
  "SUB" -> TokenType.SUB,
  "OR" -> TokenType.OR,
  "AND" -> TokenType.AND,
  "NOT" -> TokenType.NOT,
  "RETURN" -> TokenType.RETURN,
  "ASM" -> TokenType.ASM,
  "STATIC" -> TokenType.STATIC,
  "STRUCT" -> TokenType.STRUCT,
  "SIZEOF" -> TokenType.SIZEOF,
  "ALLOC" -> TokenType.ALLOC,
  "FALSE" -> TokenType.FALSE,
  "TRUE" -> TokenType.TRUE,
  "NULL" -> TokenType.NULL
).map((k, v) => (k.toLowerCase(), v))