package parser

import "core:fmt"
import "core:mem"
import "core:strconv"

import "../ast"
import tok "../tokens"

allocated_dyn_arrs := make([dynamic]^[dynamic]^ast.Expr)

Parser :: struct {
	tokens:  ^[]tok.Token,
	current: int,
	arena:   mem.Allocator,
}

init_parser :: proc(tokens: ^[]tok.Token, arena: mem.Allocator) -> ^Parser {
	parser := new(Parser, arena)
	parser^ = Parser {
		tokens  = tokens,
		current = 0,
		arena   = arena,
	}
	return parser
}

parse_expr :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	return parse_assignment(p, arena)
}

parse_assignment :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	expr := parse_equality(p, arena)
	if match(p, .Eq) {
		#partial switch t in expr {
		case ast.Ident:
			break // noop
		case:
			fmt.eprintln("Invalid assignment target")
		}
		name := expr.(ast.Ident).Name
		value := parse_assignment(p, arena)
		return ast.make_assign(name, value, arena)
	}
	return expr
}

parse_equality :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	expr := parse_comparison(p, arena)
	for match(p, .EqEq, .NotEq) {
		op := previous(p)
		right := parse_comparison(p, arena)
		expr = ast.make_binop(expr, right, op.lexeme, arena)
	}
	return expr
}

parse_stmt :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	if match(p, .KeywordLet) {
		name := consume(p, .Ident, "Expected variable name").lexeme
		consume(p, .Eq, "Expected '=' after name")
		value := parse_expr(p, arena)
		return ast.make_assign(name, value, arena)
	}
	if match(p, .KeywordIf) {
		cond := parse_expr(p, arena)
		consume(p, .KeywordThen, "Expected 'then'")
		then_branch := parse_stmt(p, arena)
		elifs := make([dynamic]^ast.Expr, 0)
		for match(p, .KeywordElif) {
			elif_cond := parse_expr(p, arena)
			consume(p, .KeywordThen, "Expected 'then' after elif condition")
			elif_body := parse_stmt(p, arena)
			// Build this elif as a stand-alone IfExpr
			elif_expr := ast.make_if(elif_cond, []^ast.Expr{elif_body}, {}, {}, p.arena)
			append(&elifs, elif_expr)
		}
		else_branch := make([]^ast.Expr, 0)
		if match(p, .KeywordElse) {
			else_stmt := parse_stmt(p, arena)
			else_branch = []^ast.Expr{else_stmt}
		}
		consume(p, .KeywordEnd, "Expected 'end' to close if expression")
		return ast.make_if(cond, []^ast.Expr{then_branch}, elifs[:], else_branch, p.arena)
	}
	if match(p, .KeywordWhile) {
		cond := parse_expr(p, arena)
		body := parse_block(p, arena)
		return ast.make_loop(cond, []^ast.Expr{body}, arena)
	}
	return parse_expr(p, arena)
}


parse_stmt_block_until :: proc(p: ^Parser, arena: mem.Allocator, stop_tokens: []tok.TokenKind) -> []^ast.Expr {
	stmts := new([dynamic]^ast.Expr)
	stmts^ = make([dynamic]^ast.Expr, 0)
	append(&allocated_dyn_arrs, stmts)
	for !is_at_end(p) && !tok.token_is_one_of(peek(p).kind, stop_tokens) {
		append(stmts, parse_stmt(p, arena))
	}
	return stmts[:]
}

parse_block :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	consume(p, .LBrace, "Expected '{' to start block")
	exprs := make([dynamic]^ast.Expr, 0)
	for !check(p, .RBrace) && !is_at_end(p) {
		stmt := parse_stmt(p, arena)
		append(&exprs, stmt)
	}
	consume(p, .RBrace, "Expected '}' to end block")
	return ast.make_block(exprs[:], arena)
}

parse_factor :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	expr := parse_primary(p, arena)
	for match(p, .Star, .Slash) {
		op := previous(p)
		right := parse_primary(p, arena)
		expr = ast.make_binop(expr, right, op.lexeme, arena)
	}
	return expr
}

parse_term :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	expr := parse_factor(p, arena)
	for match(p, .Plus, .Minus) {
		op := previous(p)
		right := parse_factor(p, arena)
		expr = ast.make_binop(expr, right, op.lexeme, arena)
	}
	return expr
}

parse_comparison :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	expr := parse_term(p, arena) // next level down
	for match(p, .Gt, .Ge, .Lt, .Le) {
		op := previous(p)
		right := parse_term(p, arena)
		expr = ast.make_binop(expr, right, op.lexeme, arena)
	}
	return expr
}

parse_primary :: proc(p: ^Parser, arena: mem.Allocator) -> ^ast.Expr {
	token := advance(p)
	#partial switch token.kind {
	case .Number:
		val := parse_int_literal(token.lexeme)
		return ast.make_number(int(val), p.arena)
	case .Ident:
		if len(token.lexeme) == 0 {
			panic("Empty identifier found during parse")
		}
		return ast.make_ident(token.lexeme, p.arena)
	case .KeywordIf:
		expr := parse_expr(p, arena)
		consume(p, .KeywordThen, "Expected keyword 'then' after if expression")
		return expr
	case:
		fmt.printfln("%v", p.tokens)
	}
	panic("Expected expression")
}

parse_int_literal :: proc(s: string) -> i64 {
	return strconv.parse_i64(s) or_else panic("Invalid number")
}

match :: proc(p: ^Parser, kinds: ..tok.TokenKind) -> bool {
	for kind in kinds {
		if check(p, kind) {
			_ = advance(p)
			return true
		}
	}
	return false
}

check :: proc(p: ^Parser, kind: tok.TokenKind) -> bool {
	if is_at_end(p) do return false
	return peek(p).kind == kind
}

advance :: proc(p: ^Parser) -> tok.Token {
	if !is_at_end(p) {
		p.current += 1
	}
	return previous(p)
}

consume :: proc(p: ^Parser, kind: tok.TokenKind, msg: string) -> tok.Token {
	if check(p, kind) do return advance(p)
	// ideally raise syntax error here
	panic(msg)
}

peek :: proc(p: ^Parser) -> tok.Token {
	return p.tokens[p.current]
}

previous :: proc(p: ^Parser) -> tok.Token {
	return p.tokens[p.current - 1]
}

is_at_end :: proc(p: ^Parser) -> bool {
	return peek(p).kind == .Eof
}

free_allocated_dyn_arrs :: proc() {
	for arr in allocated_dyn_arrs {
		delete(arr^)
		free(arr)
	}
	delete(allocated_dyn_arrs)
}

