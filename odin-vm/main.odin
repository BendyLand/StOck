package main

import "core:fmt"

import "instructions"
import "tests"
import "vm"

main :: proc() {
	tests.run_tests()
	types.free_allocated_strings()
	ast.free_allocated_dyn_arrs()
	ast.free_allocated_exprs()
	vm.free_allocated_dyn_arrs()
	compile.free_allocated_labels()
	compile.free_allocated_str_arrs()
}

