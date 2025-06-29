package main

import "core:fmt"

import "tests"
import "instructions"
import "vm"

main :: proc() {
	ast := instructions.get_ast_from_go()
	state := vm.VM {
		program = ast,
	    symbols = make(map[string]int),
	    next_slot = 0,
	}
	instructions.show_instructions(ast)
	vm.run_vm(&state)
}

