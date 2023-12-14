package main

// Lexer

func nextChar() {
	if c == '\n' {
		line = line + 1
		col = 0
	}
	c = getc()
	col = col + 1
}

func itoa(n int) string {
	if n < 0 {
		return "-" + itoa(-n)
	}
	if n < 10 {
		return char(n + '0')
	}
	return itoa(n/10) + itoa(n%10)
}

func error(msg string) {
	log("\n" + itoa(line) + ":" + itoa(col) + ": " + msg + "\n")
	exit(1)
}

func isDigit(ch int) bool {
	return ch >= '0' && ch <= '9'
}

func isAlpha(ch int) bool {
	return ch >= 'a' && ch <= 'z' || ch >= 'A' && ch <= 'Z'
}

func find(names []string, name string) int {
	i := 0
	for i < len(names) {
		if names[i] == name {
			return i
		}
		i = i + 1
	}
	return -1
}

func expectChar(ch int) {
	if c != ch {
		error("expected '" + char(ch) + "' not '" + char(c) + "'")
	}
	nextChar()
}

func tokenChoice(oneCharToken int, secondCh int, twoCharToken int) {
	nextChar()
	if c == secondCh {
		nextChar()
		token = twoCharToken
	} else {
		token = oneCharToken
	}
}

func next() {
	// Skip whitespace and comments, and look for / operator
	for c == '/' || c == ' ' || c == '\t' || c == '\r' || c == '\n' {
		if c == '/' {
			nextChar()
			if c != '/' {
				token = tDivide
				return
			}
			nextChar()
			// Comment, skip till end of line
			for c >= 0 && c != '\n' {
				nextChar()
			}
		} else if c == '\n' {
			nextChar()
			// Semicolon insertion: golang.org/ref/spec#Semicolons
			if token == tIdent || token == tIntLit || token == tStrLit ||
				token == tReturn || token == tRParen ||
				token == tRBracket || token == tRBrace {
				token = tSemicolon
				return
			}
		} else {
			nextChar()
		}
	}
	if c < 0 {
		// End of file
		token = tEOF
		return
	}

	// Integer literal
	if isDigit(c) {
		tokenInt = c - '0'
		nextChar()
		for isDigit(c) {
			tokenInt = tokenInt*10 + c - '0'
			nextChar()
		}
		token = tIntLit
		return
	}

	// Character literal
	if c == '\'' {
		nextChar()
		if c == '\n' {
			error("newline not allowed in character literal")
		}
		if c == '\\' {
			// Escape character
			nextChar()
			if c == '\'' {
				tokenInt = '\''
			} else if c == '\\' {
				tokenInt = '\\'
			} else if c == 't' {
				tokenInt = '\t'
			} else if c == 'r' {
				tokenInt = '\r'
			} else if c == 'n' {
				tokenInt = '\n'
			} else {
				error("unexpected escape '\\" + char(c) + "'")
			}
			nextChar()
		} else {
			tokenInt = c
			nextChar()
		}
		expectChar('\'')
		token = tIntLit
		return
	}

	// String literal
	if c == '"' {
		nextChar()
		tokenStr = ""
		for c >= 0 && c != '"' {
			if c == '\n' {
				error("newline not allowed in string")
			}
			if c == '\\' {
				// Escape character
				nextChar()
				if c == '"' {
					c = '"'
				} else if c == '\\' {
					c = '\\'
				} else if c == 't' {
					c = '\t'
				} else if c == 'r' {
					c = '\r'
				} else if c == 'n' {
					c = '\n'
				} else {
					error("unexpected escape \"\\" + char(c) + "\"")
				}
			}
			tokenStr = tokenStr + char(c)
			nextChar()
		}
		expectChar('"')
		token = tStrLit
		return
	}

	// Keyword or identifier
	if isAlpha(c) || c == '_' {
		tokenStr = char(c)
		nextChar()
		for isAlpha(c) || isDigit(c) || c == '_' {
			tokenStr = tokenStr + char(c)
			nextChar()
		}
		index := find(tokens, tokenStr)
		if index >= tIf && index <= tPackage {
			// Keyword
			token = index
		} else {
			// Otherwise it's an identifier
			token = tIdent
		}
		return
	}

	// Single-character tokens (token is ASCII value)
	if c == '+' || c == '-' || c == '*' || c == '%' || c == ';' ||
		c == ',' || c == '(' || c == ')' || c == '{' || c == '}' ||
		c == '[' || c == ']' {
		token = c
		nextChar()
		return
	}

	// One or two-character tokens
	if c == '=' {
		tokenChoice(tAssign, '=', tEq)
		return
	} else if c == '<' {
		tokenChoice(tLess, '=', tLessEq)
		return
	} else if c == '>' {
		tokenChoice(tGreater, '=', tGreaterEq)
		return
	} else if c == '!' {
		tokenChoice(tNot, '=', tNotEq)
		return
	} else if c == ':' {
		tokenChoice(tColon, '=', tDeclAssign)
		return
	}

	// Two-character tokens
	if c == '|' {
		nextChar()
		expectChar('|')
		token = tOr
		return
	} else if c == '&' {
		nextChar()
		expectChar('&')
		token = tAnd
		return
	}

	error("unexpected '" + char(c) + "'")
}

// Escape given string; use "delim" as quote character.
func escape(s string, delim string) string {
	i := 0
	quoted := delim
	for i < len(s) {
		if s[i] == '"' {
			quoted = quoted + "\\\""
		} else if s[i] == '\\' {
			quoted = quoted + "\\\\"
		} else if s[i] == '\t' {
			quoted = quoted + "\\t"
		} else if s[i] == '\r' {
			quoted = quoted + "\\r"
		} else if s[i] == '\n' {
			quoted = quoted + "\\n"
		} else if s[i] == '`' {
			quoted = quoted + "\\`"
		} else {
			quoted = quoted + char(int(s[i]))
		}
		i = i + 1
	}
	return quoted + delim
}

func tokenName(t int) string {
	if t > ' ' {
		return char(t)
	}
	return tokens[t]
}
