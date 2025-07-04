package main

import "core:fmt"

import "instructions"
import "tests"
import "vm"

main :: proc() {
	tests.run_tests()
}

