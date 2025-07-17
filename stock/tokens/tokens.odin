package tokens

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

allocated_dyn_arrs := make([dynamic][dynamic]Token)

TokenKind :: enum {
	Ident,
	Number,
	KeywordLet,
	KeywordIf,
	KeywordElif,
	KeywordElse,
	KeywordWhile,
	KeywordThen,
	KeywordDo,
	KeywordEnd,
	LParen,
	RParen,
	LBrace,
	RBrace,
	Plus,
	Minus,
	Star,
	Slash,
	Eq, // '='
	EqEq, // '=='
	NotEq, // '!='
	Lt,
	Le,
	Gt,
	Ge,
	Semicolon,
	Eof,
}

Token :: struct {
	kind:   TokenKind,
	lexeme: string,
	line:   int,
	col:  int,
}

// Caller must free return value
lex :: proc(source: string, arena: mem.Allocator) -> ^[]Token {
	tokens := make([dynamic]Token, 0)
	i := 0
	line := 1
	col := 1
	for i < len(source) {
		start_col := col
		c := peek(source, i)
		i += 1
		col += 1
		// Skip whitespace
		if c == ' ' || c == '\t' {
			continue
		}
		if c == '\n' {
			line += 1
			col = 1
			continue
		}
		switch c {
		case '(':
			append(&tokens, Token{kind = .LParen, lexeme = "(", line = line, col = start_col})
		case ')':
			append(&tokens, Token{kind = .RParen, lexeme = ")", line = line, col = start_col})
		case '{':
			append(&tokens, Token{kind = .LBrace, lexeme = "{", line = line, col = start_col})
		case '}':
			append(&tokens, Token{kind = .RBrace, lexeme = "}", line = line, col = start_col})
		case '+':
			append(&tokens, Token{kind = .Plus, lexeme = "+", line = line, col = start_col})
		case '-':
			append(&tokens, Token{kind = .Minus, lexeme = "-", line = line, col = start_col})
		case '*':
			append(&tokens, Token{kind = .Star, lexeme = "*", line = line, col = start_col})
		case '/':
			append(&tokens, Token{kind = .Slash, lexeme = "/", line = line, col = start_col})
		case '=':
			if match_char('=', source, &i) {
				append(&tokens, Token{kind = .EqEq, lexeme = "==", line = line, col = start_col})
			}
			else {
				append(&tokens, Token{kind = .Eq, lexeme = "=", line = line, col = start_col})
			}
		case '!':
			if match_char('=', source, &i) {
				append(&tokens, Token{kind = .NotEq, lexeme = "!=", line = line, col = start_col})
			}
		case '<':
			if match_char('=', source, &i) {
				append(&tokens, Token{kind = .Le, lexeme = "<=", line = line, col = start_col})
			}
			else {
				append(&tokens, Token{kind = .Lt, lexeme = "<", line = line, col = start_col})
			}
		case '>':
			if match_char('=', source, &i) {
				append(&tokens, Token{kind = .Ge, lexeme = ">=", line = line, col = start_col})
			}
			else {
				append(&tokens, Token{kind = .Gt, lexeme = ">", line = line, col = start_col})
			}
		case:
			// Identifiers or keywords
			if is_alpha(c) {
				start := i - 1
				for is_alnum(peek(source, i)) {
					i += 1
					col += 1
				}
				lexeme := source[start:i]
				kind := keyword_or_ident(lexeme)
				append(&tokens, Token{kind = kind, lexeme = lexeme, line = line, col = start_col})
				continue
			}
			// Numbers
			if is_digit(c) {
				start := i - 1
				for is_digit(peek(source, i)) {
					i += 1
					col += 1
				}
				lexeme := source[start:i]
				append(
					&tokens,
					Token{kind = .Number, lexeme = lexeme, line = line, col = start_col},
				)
				continue
			}
		// Unknown character
		// Optionally: report error or skip
		}
	}
	append(&tokens, Token{kind = .Eof, lexeme = "", line = line, col = col})
	append(&allocated_dyn_arrs, tokens)
	result := new([]Token)
	result^ = tokens[:]
	return result
}

to_lexeme :: proc(kind: TokenKind) -> string {
	result: string
	switch kind {
	case .Ident:
		result = ""
	case .Number:
		result = ""
	case .KeywordLet:
		result = "let"
	case .KeywordIf:
		result = "if"
	case .KeywordElif:
		result = "elif"
	case .KeywordElse:
		result = "else"
	case .KeywordWhile:
		result = "while"
	case .KeywordThen:
		result = "then"
	case .KeywordDo:
		result = "do"
	case .KeywordEnd:
		result = "end"
	case .LParen:
		result = "("
	case .RParen:
		result = ")"
	case .LBrace:
		result = "{"
	case .RBrace:
		result = "}"
	case .Plus:
		result = "+"
	case .Minus:
		result = "-"
	case .Star:
		result = "*"
	case .Slash:
		result = "/"
	case .Eq:
		result = "="
	case .EqEq:
		result = "=="
	case .NotEq:
		result = "!="
	case .Lt:
		result = "<"
	case .Le:
		result = "<="
	case .Gt:
		result = ">"
	case .Ge:
		result = ">="
	case .Semicolon:
		result = ";"
	case .Eof:
		result = ""
	}
	return result
}

token :: proc(kind: TokenKind, line: int, col: int) -> ^Token {
	result := new(Token)
	result^ = Token {
		kind   = kind,
		lexeme = to_lexeme(kind),
		line   = line,
		col    = col,
	}
	return result
}

is_alpha :: proc(c: u8) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

is_digit :: proc(c: u8) -> bool {
	return c >= '0' && c <= '9'
}

is_alnum :: proc(c: u8) -> bool {
	return is_alpha(c) || is_digit(c)
}

keyword_or_ident :: proc(s: string) -> TokenKind {
	switch s {
	case "let":
		return .KeywordLet
	case "if":
		return .KeywordIf
	case "elif":
		return .KeywordElif
	case "else":
		return .KeywordElse
	case "then":
		return .KeywordThen
	case "do":
		return .KeywordDo
	case "end":
		return .KeywordEnd
	case "while":
		return .KeywordWhile
	case:
		return .Ident
	}
}

tokenize :: proc(source: string) -> []Token {
	tokens := make([dynamic]Token, 0)
	i := 0
	len := len(source)
	for i < len {
		c := source[i]
		// Skip whitespace
		if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
			i += 1
			continue
		}
		// Keywords
		if strings.has_prefix(source[i:], "let") {
			t := Token {
				kind   = .KeywordLet,
				lexeme = "let",
			}
			append(&tokens, t)
			i += 3
			continue
		}
		if strings.has_prefix(source[i:], "if") {
			t := Token {
				kind   = .KeywordIf,
				lexeme = "if",
			}
			append(&tokens, t)
			i += 2
			continue
		}
		if strings.has_prefix(source[i:], "then") {
			t := Token {
				kind   = .KeywordThen,
				lexeme = "then",
			}
			append(&tokens, t)
			i += 4
			continue
		}
		if strings.has_prefix(source[i:], "end") {
			t := Token {
				kind   = .KeywordEnd,
				lexeme = "end",
			}
			append(&tokens, t)
			i += 3
			continue
		}
		// Identifier
		if is_alpha(c) {
			start := i
			for i < len && (is_alpha(source[i]) || is_digit(source[i])) {
				i += 1
			}
			lexeme := source[start:i]
			t := Token {
				kind   = .Ident,
				lexeme = lexeme,
			}
			append(&tokens, t)
			continue
		}
		// Number
		if is_digit(c) {
			start := i
			for i < len && is_digit(source[i]) {
				i += 1
			}
			lexeme := source[start:i]
			t := Token {
				kind   = .Number,
				lexeme = lexeme,
			}
			append(&tokens, t)
			continue
		}
		// Symbols
		if c == '=' {
			t := Token {
				kind   = .Eq,
				lexeme = "=",
			}
			append(&tokens, t)
			i += 1
			continue
		}
		// TODO: add other operators/parens/braces as needed
		// Unknown character fallback
		i += 1
	}
	append(&tokens, Token{kind = .Eof, lexeme = ""})
	return tokens[:]
}

peek :: proc(source: string, i: int) -> u8 {
	if i >= len(source) do return 0
	return source[i]
}

match_char :: proc(expected: u8, source: string, i_ptr: ^int) -> bool {
	if peek(source, i_ptr^) == expected {
		i_ptr^ += 1
		return true
	}
	return false
}

token_is_one_of :: proc(kind: TokenKind, kinds: []TokenKind) -> bool {
	for k in kinds {
		if k == kind {
			return true
		}
	}
	return false
}

free_allocated_dyn_arrs :: proc () {
	for arr in allocated_dyn_arrs {
		delete(arr)
	}
	delete(allocated_dyn_arrs)
}

