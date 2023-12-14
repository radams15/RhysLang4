package main

// Recursive-descent parser

func expect(expected int, msg string) {
	if token != expected {
		error("expected " + msg + " not " + tokenName(token))
	}
	next()
}

func Literal() int {
	if token == tIntLit {
		genIntLit(tokenInt)
		next()
		return typeInt
	} else if token == tStrLit {
		genStrLit(tokenStr)
		next()
		return typeString
	} else {
		error("expected integer or string literal")
		return 0
	}
}

func identifier(msg string) {
	expect(tIdent, msg)
}

func Operand() int {
	if token == tIntLit || token == tStrLit {
		return Literal()
	} else if token == tIdent {
		name := tokenStr
		identifier("identifier")
		return genIdentifier(name)
	} else {
		error("expected literal or identifier")
		return 0
	}
}

func ExpressionList() int {
	firstType := Expression()
	for token == tComma {
		next()
		Expression()
	}
	return firstType
}

func Arguments() int {
	funcName := tokenStr // function name will still be in tokenStr
	expect(tLParen, "(")
	arg1Type := typeVoid
	if token != tRParen {
		arg1Type = ExpressionList()
	}
	expect(tRParen, ")")

	// Replace "generic" built-in functions with type-specific versions
	if funcName == "append" {
		if arg1Type == typeSliceInt {
			funcName = "_appendInt"
		} else if arg1Type == typeSliceStr {
			funcName = "_appendString"
		} else {
			error("can't append to " + typeName(arg1Type))
		}
	} else if funcName == "len" {
		if arg1Type == typeString {
			funcName = "len"
		} else if arg1Type == typeSliceInt || arg1Type == typeSliceStr {
			funcName = "_lenSlice"
		} else {
			error("can't get length of " + typeName(arg1Type))
		}
	}
	return genCall(funcName)
}

func indexExpr() {
	typ := Expression()
	if typ != typeInt {
		error("slice index must be int")
	}
}

func PrimaryExpr() int {
	typ := Operand()
	if token == tLParen {
		return Arguments()
	} else if token == tLBracket {
		next()
		if token == tColon {
			if typ != typeSliceInt && typ != typeSliceStr {
				error("slice expression requires slice type")
			}
			next()
			indexExpr()
			expect(tRBracket, "]")
			genSliceExpr()
			return typ
		}
		indexExpr()
		expect(tRBracket, "]")
		return genSliceFetch(typ)
	}
	return typ
}

func UnaryExpr() int {
	if token == tPlus || token == tMinus || token == tNot {
		op := token
		next()
		typ := UnaryExpr()
		genUnary(op, typ)
		return typ
	}
	return PrimaryExpr()
}

func mulExpr() int {
	typ := UnaryExpr()
	for token == tTimes || token == tDivide || token == tModulo {
		op := token
		next()
		typRight := UnaryExpr()
		typ = genBinary(op, typ, typRight)
	}
	return typ
}

func addExpr() int {
	typ := mulExpr()
	for token == tPlus || token == tMinus {
		op := token
		next()
		typRight := mulExpr()
		typ = genBinary(op, typ, typRight)
	}
	return typ
}

func comparisonExpr() int {
	typ := addExpr()
	for token == tEq || token == tNotEq || token == tLess || token == tLessEq ||
		token == tGreater || token == tGreaterEq {
		op := token
		next()
		typRight := addExpr()
		typ = genBinary(op, typ, typRight)
	}
	return typ
}

func andExpr() int {
	typ := comparisonExpr()
	for token == tAnd {
		op := token
		next()
		typRight := comparisonExpr()
		typ = genBinary(op, typ, typRight)
	}
	return typ
}

func orExpr() int {
	typ := andExpr()
	for token == tOr {
		op := token
		next()
		typRight := andExpr()
		typ = genBinary(op, typ, typRight)
	}
	return typ
}

func Expression() int {
	return orExpr()
}

func PackageClause() {
	expect(tPackage, "\"package\"")
	identifier("package identifier")
}

func Type() int {
	if token == tLBracket {
		next()
		expect(tRBracket, "]")
		name := tokenStr
		identifier("\"int\" or \"string\"")
		if name == "int" || name == "bool" {
			return typeSliceInt
		} else if name == "string" {
			return typeSliceStr
		} else {
			error("only []int and []string are supported")
		}
	}
	name := tokenStr
	identifier("\"int\" or \"string\"")
	if name == "int" || name == "bool" {
		return typeInt
	} else if name == "string" {
		return typeString
	} else {
		error("only int and string are supported")
	}
	return typeVoid
}

func defineLocal(typ int, name string) {
	locals = append(locals, name)
	localTypes = append(localTypes, typ)
}

func VarSpec() {
	// We only support a single identifier, not a list
	varName := tokenStr
	identifier("variable identifier")
	typ := Type()
	if curFunc != "" {
		error("\"var\" not supported inside functions")
	}
	globals = append(globals, varName)
	globalTypes = append(globalTypes, typ)
	if token == tAssign {
		error("assignment not supported for top-level var")
	}
}

func VarDecl() {
	expect(tVar, "\"var\"")
	expect(tLParen, "(")
	for token != tRParen {
		VarSpec()
		expect(tSemicolon, ";")
	}
	expect(tRParen, ")")
}

func ConstSpec() {
	// We only support typed integer constants
	name := tokenStr
	consts = append(consts, name)
	identifier("variable identifier")
	typ := Type()
	if typ != typeInt {
		error("constants must be typed int")
	}
	expect(tAssign, "=")
	value := tokenInt
	expect(tIntLit, "integer literal")
	genConst(name, value)
}

func ConstDecl() {
	expect(tConst, "\"const\"")
	expect(tLParen, "(")
	for token != tRParen {
		ConstSpec()
		expect(tSemicolon, ";")
	}
	expect(tRParen, ")")
}

func ParameterDecl() {
	paramName := tokenStr
	identifier("parameter name")
	typ := Type()
	defineLocal(typ, paramName)
	funcSigs = append(funcSigs, typ)
	resultIndex := funcSigIndexes[len(funcSigIndexes)-1]
	funcSigs[resultIndex+1] = funcSigs[resultIndex+1] + 1 // increment numArgs
}

func ParameterList() {
	ParameterDecl()
	for token == tComma {
		next()
		ParameterDecl()
	}
}

func Parameters() {
	expect(tLParen, "(")
	if token != tRParen {
		ParameterList()
	}
	expect(tRParen, ")")
}

func Signature() {
	funcSigs = append(funcSigs, typeVoid) // space for result type
	funcSigs = append(funcSigs, 0)        // space for numArgs
	Parameters()
	if token != tLBrace {
		typ := Type()
		resultIndex := funcSigIndexes[len(funcSigIndexes)-1]
		funcSigs[resultIndex] = typ // set result type
	}
}

func SimpleStmt() {
	// Funky parsing here to handle assignments
	identName := tokenStr
	expect(tIdent, "assignment or call statement")
	if token == tAssign {
		next()
		lhsType := varType(identName)
		rhsType := Expression()
		if lhsType != rhsType {
			error("can't assign " + typeName(rhsType) + " to " +
				typeName(lhsType))
		}
		genAssign(identName)
	} else if token == tDeclAssign {
		next()
		typ := Expression()
		defineLocal(typ, identName)
		genAssign(identName)
	} else if token == tLParen {
		genIdentifier(identName)
		typ := Arguments()
		genDiscard(typ) // discard return value
	} else if token == tLBracket {
		next()
		indexExpr()
		expect(tRBracket, "]")
		expect(tAssign, "=")
		Expression()
		genSliceAssign(identName)
	} else {
		error("expected assignment or call not " + tokenName(token))
	}
}

func ReturnStmt() {
	expect(tReturn, "\"return\"")
	if token != tSemicolon {
		typ := Expression()
		genReturn(typ)
	} else {
		genReturn(typeVoid)
	}
}

func newLabel() string {
	labelNum = labelNum + 1
	return "label" + itoa(labelNum)
}

func IfStmt() {
	expect(tIf, "\"if\"")
	Expression()
	ifLabel := newLabel()
	genJumpIfZero(ifLabel) // jump to else or end of if block
	Block()
	if token == tElse {
		next()
		elseLabel := newLabel()
		genJump(elseLabel) // jump past else block
		genLabel(ifLabel)
		if token == tIf {
			IfStmt()
		} else {
			Block()
		}
		genLabel(elseLabel)
	} else {
		genLabel(ifLabel)
	}
}

func ForStmt() {
	expect(tFor, "\"for\"")
	loopLabel := newLabel()
	genLabel(loopLabel) // top of loop
	Expression()
	doneLabel := newLabel()
	genJumpIfZero(doneLabel) // jump to after loop if done
	Block()
	genJump(loopLabel) // go back to top of loop
	genLabel(doneLabel)
}

func Statement() {
	if token == tIf {
		IfStmt()
	} else if token == tFor {
		ForStmt()
	} else if token == tReturn {
		ReturnStmt()
	} else {
		SimpleStmt()
	}
}

func StatementList() {
	for token != tRBrace {
		Statement()
		expect(tSemicolon, ";")
	}
}

func Block() {
	expect(tLBrace, "{")
	StatementList()
	expect(tRBrace, "}")
}

func FunctionBody() {
	Block()
}

func FunctionDecl() {
	expect(tFunc, "\"func\"")
	curFunc = tokenStr
	genFuncStart(tokenStr)
	funcs = append(funcs, tokenStr)
	funcSigIndexes = append(funcSigIndexes, len(funcSigs))
	identifier("function name")
	Signature()
	FunctionBody()
	genFuncEnd()
	locals = locals[:0]
	localTypes = localTypes[:0]
	curFunc = ""
}

func TopLevelDecl() {
	if token == tVar {
		VarDecl()
	} else if token == tConst {
		// ConstDecl only supported at top level
		ConstDecl()
	} else if token == tFunc {
		FunctionDecl()
	} else {
		error("expected \"var\", \"const\", or \"func\"")
	}
}

func SourceFile() {
	PackageClause()
	expect(tSemicolon, ";")

	for token == tVar || token == tFunc || token == tConst {
		TopLevelDecl()
		expect(tSemicolon, ";")
	}

	expect(tEOF, "end of file")
}
