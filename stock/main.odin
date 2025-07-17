package main

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"
import "core:strings"

import "ast"
import "compile"
import "instructions"
import "parser"
import "tokens"
import "utils"
import "vm"

main :: proc() {
	source := `
	let x = 5
	if x > 0 then
	  x = x - 1
	else
	  x = 0
	end
	`


	arena := utils.make_arena()
	defer free(arena)
	alloc := virtual.arena_allocator(arena)
	toks := tokens.lex(source, alloc) 
	defer free(toks)
	p := parser.init_parser(toks, alloc)
	// Emit bytecode
	program := new([dynamic]^ast.Expr)
	defer free(program)
	defer delete_dynamic_array(program^)
	for !parser.is_at_end(p) {
		stmts := parser.parse_stmt_block_until(p, alloc, []tokens.TokenKind{.KeywordEnd})
		for stmt in stmts {
			append(program, stmt)
		}
	}
	emitter := compile.emit_program(program, alloc)
	// Print resolved bytecode
	raw_code := instructions.resolve_labels(emitter.code[:], alloc)
	instructions.show_instructions(raw_code)
	free_all_dyn_arrs(arena)
}

free_all_dyn_arrs :: proc(arena: ^virtual.Arena) {
	virtual.arena_free_all(arena)
	ast.free_allocated_dyn_arrs()
	compile.free_allocated_dyn_arrs()
	instructions.free_allocated_dyn_arrs()
	vm.free_allocated_dyn_arrs()
	parser.free_allocated_dyn_arrs()
	tokens.free_allocated_dyn_arrs()
}

