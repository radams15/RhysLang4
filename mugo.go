// Mugo: compiler for a (micro) subset of Go

package main

var (
	// Lexer variables
	c    int // current lexer byte
	line int // current line and column
	col  int

	// Parser-compiler variables
	token          int      // current parser token
	tokenInt       int      // integer value of current token (if applicable)
	tokenStr       string   // string value of current token (if applicable)
	curFunc        string   // current function name, or "" if not in a func
	tokens         []string // token names
	types          []string // type names
	typeSizes      []int    // type sizes in bytes
	labelNum       int      // current label number
	consts         []string // constant names
	globals        []string // global names and types
	globalTypes    []int
	locals         []string // local names and types
	localTypes     []int
	funcs          []string // function names
	funcSigIndexes []int    // indexes into funcSigs
	funcSigs       []int    // for each func: retType N arg1Type ... argNType
	strs           []string // string constants
)

const (
	localSpace int = 64      // max space for locals declared with := (not arguments)
	heapSize   int = 1048576 // 1MB "heap"

	// Types
	typeVoid     int = 1 // only used as return "type"
	typeInt      int = 2
	typeString   int = 3
	typeSliceInt int = 4
	typeSliceStr int = 5

	// Keywords
	tIf      int = 1
	tElse    int = 2
	tFor     int = 3
	tVar     int = 4
	tConst   int = 5
	tFunc    int = 6
	tReturn  int = 7
	tPackage int = 8

	// Literals, identifiers, and EOF
	tIntLit int = 9
	tStrLit int = 10
	tIdent  int = 11
	tEOF    int = 12

	// Two-character tokens
	tOr         int = 13
	tAnd        int = 14
	tEq         int = 15
	tNotEq      int = 16
	tLessEq     int = 17
	tGreaterEq  int = 18
	tDeclAssign int = 19

	// Single-character tokens (these use the ASCII value)
	tPlus      int = '+'
	tMinus     int = '-'
	tTimes     int = '*'
	tDivide    int = '/'
	tModulo    int = '%'
	tComma     int = ','
	tSemicolon int = ';'
	tColon     int = ':'
	tAssign    int = '='
	tNot       int = '!'
	tLess      int = '<'
	tGreater   int = '>'
	tLParen    int = '('
	tRParen    int = ')'
	tLBrace    int = '{'
	tRBrace    int = '}'
	tLBracket  int = '['
	tRBracket  int = ']'
)

func addFunc(name string, resultType int, numArgs int, arg1Type int, arg2Type int) {
	funcs = append(funcs, name)
	funcSigIndexes = append(funcSigIndexes, len(funcSigs))
	funcSigs = append(funcSigs, resultType)
	funcSigs = append(funcSigs, numArgs)
	if numArgs > 0 {
		funcSigs = append(funcSigs, arg1Type)
	}
	if numArgs > 1 {
		funcSigs = append(funcSigs, arg2Type)
	}
}

func addToken(name string) {
	tokens = append(tokens, name)
}

func addType(name string, size int) {
	types = append(types, name)
	typeSizes = append(typeSizes, size)
}

func main() {
	// Builtin functions (defined in genProgramStart; Go versions in gofuncs.go)
	addFunc("print", typeVoid, 1, typeString, 0)
	addFunc("log", typeVoid, 1, typeString, 0)
	addFunc("getc", typeInt, 0, 0, 0)
	addFunc("exit", typeVoid, 1, typeInt, 0)
	addFunc("char", typeString, 1, typeInt, 0)
	addFunc("len", typeInt, 1, typeString, 0)
	addFunc("_lenSlice", typeInt, 1, typeSliceInt, 0) // works with typeSliceStr too
	addFunc("int", typeInt, 1, typeInt, 0)
	addFunc("append", typeSliceInt, 2, typeSliceInt, typeInt)
	addFunc("_appendInt", typeSliceInt, 2, typeSliceInt, typeInt)
	addFunc("_appendString", typeSliceStr, 2, typeSliceStr, typeString)

	// Forward references
	addFunc("Expression", typeInt, 0, 0, 0)
	addFunc("Block", typeVoid, 0, 0, 0)

	// Token names
	addToken("") // token 0 is not valid
	addToken("if")
	addToken("else")
	addToken("for")
	addToken("var")
	addToken("const")
	addToken("func")
	addToken("return")
	addToken("package")
	addToken("integer")
	addToken("string")
	addToken("identifier")
	addToken("EOF")
	addToken("||")
	addToken("&&")
	addToken("==")
	addToken("!=")
	addToken("<=")
	addToken(">=")
	addToken(":=")

	// Type names and sizes
	addType("", 0) // type 0 is not valid
	addType("void", 0)
	addType("int", 8)
	addType("string", 16)
	addType("[]int", 24)
	addType("[]string", 24)

	genProgramStart()

	line = 1
	col = 0
	nextChar()
	next()
	SourceFile()

	genDataSections()
}
