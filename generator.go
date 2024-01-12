package main

func genProgramStart() {
    print(`start:
CALL main
HALT 0
`);

	print(`print:
ENTER
DEREF 
;SCALL2 11 str0 10 0 0
LEAVE
DROP ; size
DROP ; string
RET`);
}

func genConst(name string, value int) {
	print("CONST " + name + " " + itoa(value) + "\n")
}

func genIntLit(n int) {
    print("LDADDR " + itoa(n) + "\n")
	print("PUSH " + "\n")
}

func genStrLit(s string) {
	// Add string to strs and strAddrs tables
	index := find(strs, s)
	if index < 0 {
		// Haven't seen this string constant before, add a new one
		index = len(strs)
		strs = append(strs, s)
	}
	
	genIntLit(len(s))

	print("LDADDR str" + itoa(index) + "\n")
	print("PUSH\n")
}

func typeName(typ int) string {
	return types[typ]
}

func typeSize(typ int) int {
	return typeSizes[typ]
}

// Return offset of local variable from rbp (including arguments).
func localOffset(index int) int {
	funcIndex := find(funcs, curFunc)
	sigIndex := funcSigIndexes[funcIndex]
	numArgs := funcSigs[sigIndex+1]
	if index < numArgs {
		// Function argument local (add to rbp; args are on stack in reverse)
		offset := 16
		i := numArgs - 1
		for i > index {
			offset = offset + typeSize(localTypes[i])
			i = i - 1
		}
		return offset
	} else {
		// Declared local (subtract from rbp)
		offset := 0
		i := numArgs
		for i <= index {
			offset = offset - typeSize(localTypes[i])
			i = i + 1
		}
		return offset
	}
}

func genFetchInstrs(typ int, addr string) {
	if typ == typeInt {
		print("LDADDR " + addr + "\n")
		print("DEREF\n")
	} else if typ == typeString {
		print("push qword [" + addr + "+8]\n")
		print("push qword [" + addr + "]\n")
	} else { // slice
		print("push qword [" + addr + "+16]\n")
		print("push qword [" + addr + "+8]\n")
		print("push qword [" + addr + "]\n")
	}
}

func genLocalFetch(index int) int {
	offset := localOffset(index)
	typ := localTypes[index]
	genFetchInstrs(typ, itoa(offset))
	return typ
}

func genGlobalFetch(index int) int {
	name := globals[index]
	typ := globalTypes[index]
	genFetchInstrs(typ, name)
	return typ
}

func genConstFetch(index int) int {
	name := consts[index]
	print("push qword " + name + "\n")
	return typeInt
}

func genIdentifier(name string) int {
	localIndex := find(locals, name)
	if localIndex >= 0 {
		return genLocalFetch(localIndex)
	}
	globalIndex := find(globals, name)
	if globalIndex >= 0 {
		return genGlobalFetch(globalIndex)
	}
	constIndex := find(consts, name)
	if constIndex >= 0 {
		return genConstFetch(constIndex)
	}
	funcIndex := find(funcs, name)
	if funcIndex >= 0 {
		sigIndex := funcSigIndexes[funcIndex]
		return funcSigs[sigIndex] // result type
	}
	Error("identifier " + escape(name, "\"") + " not defined")
	return 0
}

func genAssignInstrs(typ int, addr string) {
	if typ == typeInt {
		print("pop qword [" + addr + "]\n")
	} else if typ == typeString {
		print("pop qword [" + addr + "]\n")
		print("pop qword [" + addr + "+8]\n")
	} else { // slice
		print("pop qword [" + addr + "]\n")
		print("pop qword [" + addr + "+8]\n")
		print("pop qword [" + addr + "+16]\n")
	}
}

func genLocalAssign(index int) {
	offset := localOffset(index)
	genAssignInstrs(localTypes[index], "rbp+"+itoa(offset))
}

func genGlobalAssign(index int) {
	name := globals[index]
	genAssignInstrs(globalTypes[index], name)
}

func genAssign(name string) {
	localIndex := find(locals, name)
	if localIndex >= 0 {
		genLocalAssign(localIndex)
		return
	}
	globalIndex := find(globals, name)
	if globalIndex >= 0 {
		genGlobalAssign(globalIndex)
		return
	}
	Error("identifier " + escape(name, "\"") + " not defined (or not assignable)")
}

func varType(name string) int {
	localIndex := find(locals, name)
	if localIndex >= 0 {
		return localTypes[localIndex]
	}
	globalIndex := find(globals, name)
	if globalIndex >= 0 {
		return globalTypes[globalIndex]
	}
	Error("identifier " + escape(name, "\"") + " not defined")
	return 0
}

func genSliceAssign(name string) {
	typ := varType(name)
	print("pop rax\n") // value (addr if string type)
	if typ == typeSliceStr {
		print("pop rbx\n") // value (len)
		print("pop rcx\n") // index * 2
		print("add rcx, rcx\n")
	} else {
		print("pop rcx\n")
	}
	localIndex := find(locals, name)
	if localIndex >= 0 {
		offset := localOffset(localIndex)
		print("mov rdx, [rbp+" + itoa(offset) + "]\n")
	} else {
		print("mov rdx, [" + name + "]\n")
	}
	print("mov [rdx+rcx*8], rax\n")
	if typ == typeSliceStr {
		print("mov [rdx+rcx*8+8], rbx\n")
	}
}

func genCall(name string) int {
	print("CALL " + name + "\n")
	index := find(funcs, name)
	sigIndex := funcSigIndexes[index]
	resultType := funcSigs[sigIndex]
	if resultType == typeInt {
		print("push rax\n")
	} else if resultType == typeString {
		print("push rbx\n")
		print("push rax\n")
	} else if resultType == typeSliceInt || resultType == typeSliceStr {
		print("push rcx\n")
		print("push rbx\n")
		print("push rax\n")
	}
	return resultType
}

func genFuncStart(name string) {
	print("\n")
	print(name + ":\n")
	print("ENTER\n")
}

// Return size (in bytes) of current function's arguments.
func argsSize() int {
	i := find(funcs, curFunc)
	sigIndex := funcSigIndexes[i]
	numArgs := funcSigs[sigIndex+1]
	size := 0
	i = 0
	for i < numArgs {
		size = size + typeSize(funcSigs[sigIndex+2+i])
		i = i + 1
	}
	return size
}

// Return size (in bytes) of current function's locals (excluding arguments).
func localsSize() int {
	i := find(funcs, curFunc)
	sigIndex := funcSigIndexes[i]
	numArgs := funcSigs[sigIndex+1]
	size := 0
	i = numArgs
	for i < len(locals) {
		size = size + typeSize(localTypes[i])
		i = i + 1
	}
	return size
}

func genFuncEnd() {
	size := localsSize()
	if size > localSpace {
		Error(curFunc + "'s locals too big (" + itoa(size) + " > " + itoa(localSpace) + ")\n")
	}
	print("LEAVE\n")
	size = argsSize()
	if size > 0 {
		print("ret " + itoa(size) + "\n")
	} else {
		print("RET\n")
	}
}

func genDataSections() {
	print("\n")
	print("; section .data\n")
	print("STR _strOutOfMem out of memory\\n\n")

	// String constants
	i := 0
	for i < len(strs) {
		print("STR str" + itoa(i) + " " + escape(strs[i], "") + "\n")
		i = i + 1
	}

	// Global variables
	// print("align 8\n")
	i = 0
	for i < len(globals) {
		typ := globalTypes[i]
		if typ == typeInt {
			print(globals[i] + ": dq 0\n")
		} else if typ == typeString {
			print(globals[i] + ": dq 0, 0\n") // string: address, length
		} else {
			print(globals[i] + ": dq 0, 0, 0\n") // slice: address, length, capacity
		}
		i = i + 1
	}

	// "Heap" (used for strings and slice appends)
	/*
		print("\n")
		print("section .bss\n")
		print("_heapPtr: resq 1\n")
		print("_heap: resb " + itoa(heapSize) + "\n")
		print("_heapEnd:\n")
	*/
}

func genUnary(op int, typ int) {
	if typ != typeInt {
		Error("unary operator not allowed on type " + typeName(typ))
	}
	print("pop rax\n")
	if op == tMinus {
		print("neg rax\n")
	} else if op == tNot {
		print("cmp rax, 0\n")
		print("mov rax, 0\n")
		print("setz al\n")
	}
	print("push rax\n")
}

func genBinaryString(op int) int {
	if op == tPlus {
		print("CALL _strAdd\n")
		print("push rbx\n")
		print("push rax\n")
		return typeString
	} else if op == tEq {
		print("CALL _strEq\n")
		print("push rax\n")
		return typeInt
	} else if op == tNotEq {
		print("CALL _strEq\n")
		print("cmp rax, 0\n")
		print("mov rax, 0\n")
		print("setz al\n")
		print("push rax\n")
		return typeInt
	} else {
		Error("operator " + tokenName(op) + " not allowed on strings")
		return 0
	}
}

func genBinaryInt(op int) int {
	print("pop rbx\n")
	print("pop rax\n")
	if op == tPlus {
		print("add rax, rbx\n")
	} else if op == tMinus {
		print("sub rax, rbx\n")
	} else if op == tTimes {
		print("imul rbx\n")
	} else if op == tDivide {
		print("cqo\n")
		print("idiv rbx\n")
	} else if op == tModulo {
		print("cqo\n")
		print("idiv rbx\n")
		print("mov rax, rdx\n")
	} else if op == tEq {
		print("cmp rax, rbx\n")
		print("mov rax, 0\n")
		print("sete al\n")
	} else if op == tNotEq {
		print("cmp rax, rbx\n")
		print("mov rax, 0\n")
		print("setne al\n")
	} else if op == tLess {
		print("cmp rax, rbx\n")
		print("mov rax, 0\n")
		print("setl al\n")
	} else if op == tLessEq {
		print("cmp rax, rbx\n")
		print("mov rax, 0\n")
		print("setle al\n")
	} else if op == tGreater {
		print("cmp rax, rbx\n")
		print("mov rax, 0\n")
		print("setg al\n")
	} else if op == tGreaterEq {
		print("cmp rax, rbx\n")
		print("mov rax, 0\n")
		print("setge al\n")
	} else if op == tAnd {
		print("and rax, rbx\n")
	} else if op == tOr {
		print("or rax, rbx\n")
	}
	print("push rax\n")
	return typeInt
}

func genBinary(op int, typ1 int, typ2 int) int {
	if typ1 != typ2 {
		Error("binary operands must be the same type")
	}
	if typ1 == typeString {
		return genBinaryString(op)
	} else {
		return genBinaryInt(op)
	}
}

func genReturn(typ int) {
	if typ == typeInt {
		print("pop rax\n")
	} else if typ == typeString {
		print("pop rax\n")
		print("pop rbx\n")
	} else if typ == typeSliceInt || typ == typeSliceStr {
		print("pop rax\n")
		print("pop rbx\n")
		print("pop rcx\n")
	}
	genFuncEnd()
}

func genJumpIfZero(label string) {
	print("pop rax\n")
	print("cmp rax, 0\n")
	print("jz " + label + "\n")
}

func genJump(label string) {
	print("jmp " + label + "\n")
}

func genLabel(label string) {
	print("\n")
	print(label + ":\n")
}

func genDiscard(typ int) {
	size := typeSize(typ)
	if size > 0 {
		print("add rsp, " + itoa(typeSize(typ)) + "\n")
	}
}

func genSliceExpr() {
	// Slice expression of form slice[:max]
	print("pop rax\n")  // max
	print("pop rbx\n")  // addr
	print("pop rcx\n")  // old length (capacity remains same)
	print("push rax\n") // new length
	print("push rbx\n") // addr remains same
}

func genSliceFetch(typ int) int {
	if typ == typeString {
		print("pop rax\n") // index
		print("pop rbx\n") // addr
		print("pop rcx\n") // len
		print("xor rdx, rdx\n")
		print("mov dl, [rbx+rax]\n")
		print("push rdx\n")
		return typeInt
	} else if typ == typeSliceInt {
		print("pop rax\n") // index
		print("pop rbx\n") // addr
		print("pop rcx\n") // len
		print("pop rdx\n") // cap
		print("push qword [rbx+rax*8]\n")
		return typeInt
	} else if typ == typeSliceStr {
		print("pop rax\n") // index
		print("pop rbx\n") // addr
		print("pop rcx\n") // len
		print("pop rdx\n") // cap
		print("add rax, rax\n")
		print("push qword [rbx+rax*8+8]\n")
		print("push qword [rbx+rax*8]\n")
		return typeString
	} else {
		Error("invalid slice type " + typeName(typ))
		return 0
	}
}
