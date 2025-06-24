package tests

import "core:fmt"

import "../types"
import inst "../instructions"
import "../vm"

test1 :: proc() {
	a := types.data(i64(3))
	b := types.data(i64(4))
	test := types.data(i64(7))
	data := []types.Data{a, b}
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, a),
		inst.instruction(.Push, b),
		inst.instruction(.Add, nil), // 3 + 4
		inst.instruction(.Print, nil),
		inst.instruction(.Push, test),
		inst.instruction(.Eq, nil),
		inst.instruction(.Assert, types.data("result did not match expected value (7)")),
		inst.instruction(.Halt, nil), // 7
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test2 :: proc() {
	a := types.data(i64(42))
	test := types.data(i64(84))
	program := []inst.Instruction {
		inst.instruction(.Push, a),
		inst.instruction(.Dup, nil),
		inst.instruction(.Add, nil), // 42 + 42
		inst.instruction(.Print, nil), // expect 84
		inst.instruction(.Push, test),
		inst.instruction(.Eq, nil),
		inst.instruction(.Assert, types.data("result did not match expected value (84)")),
		inst.instruction(.Halt, nil),
	}
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test3 :: proc() {
	a := types.data(i64(10))
	b := types.data(i64(20))
	test := types.data(i64(30))
	program := []inst.Instruction {
		inst.instruction(.Push, a),
		inst.instruction(.Push, b),
		inst.instruction(.Swap, nil),
		inst.instruction(.Over, nil),
		inst.instruction(.Add, nil), // 10 + 20
		inst.instruction(.Print, nil), // expect 30
		inst.instruction(.Push, test),
		inst.instruction(.Eq, nil),
		inst.instruction(.Assert, types.data("result did not match expected value (30)")),
		inst.instruction(.Halt, nil),
	}
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test4 :: proc() {
	a := types.data(i64(1))
	b := types.data(i64(2))
	c := types.data(i64(3))
	program := []inst.Instruction {
		inst.instruction(.Push, a),
		inst.instruction(.Push, b),
		inst.instruction(.Push, c),
		inst.instruction(.Rot, nil),
		inst.instruction(.Pop, nil), // should pop 1
		inst.instruction(.Print, nil), // should print 3
		inst.instruction(.Halt, nil),
	}
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test5 :: proc() {
	a := types.data(i64(5))
	b := types.data(i64(3))
	c := types.data(i64(2))
	d := types.data(i64(4))
	e := types.data(i64(7))
	program := []inst.Instruction {
		inst.instruction(.Push, a),
		inst.instruction(.Push, a),
		inst.instruction(.Eq, nil), // true
		inst.instruction(.Print, nil),
		inst.instruction(.Assert, types.data("value did not match itself (5)")),
		inst.instruction(.Push, b),
		inst.instruction(.Push, c),
		inst.instruction(.Gt, nil), // true
		inst.instruction(.Print, nil),
		inst.instruction(.Assert, types.data("result did not match expected value (3 > 2)")),
		inst.instruction(.Push, d),
		inst.instruction(.Push, e),
		inst.instruction(.Lt, nil), // true
		inst.instruction(.Print, nil),
		inst.instruction(.Assert, types.data("result did not match expected value (4 < 7)")),
		inst.instruction(.Halt, nil),
	}
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test6 :: proc() {
	a := types.data(i64(7))
	b := types.data(false)
	c := types.data(true)
	program := []inst.Instruction {
		inst.instruction(.Push, a),
		inst.instruction(.Neg, nil),
		inst.instruction(.Print, nil), // expect -7
		inst.instruction(.Push, b),
		inst.instruction(.Not, nil),
		inst.instruction(.Assert, types.data("result did not match expected result (!false)")), // should not panic
		inst.instruction(.Push, c),
		inst.instruction(.Push, b),
		inst.instruction(.Or, nil),
		inst.instruction(.Print, nil), // true
		inst.instruction(
			.Assert,
			types.data("result did not match expected result (false || true)"),
		),
		inst.instruction(.Push, c),
		inst.instruction(.Push, c),
		inst.instruction(.And, nil),
		inst.instruction(.Print, nil), // true
		inst.instruction(
			.Assert,
			types.data("result did not match expected result (true && true)"),
		),
		inst.instruction(.Halt, nil),
	}
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test7 :: proc() {
	a := types.data(i64(7))
	b := types.data(false)
	c := types.data(true)
	program := []inst.Instruction {
		inst.instruction(.Push, types.data(i64(1))),
		inst.instruction(.Push, types.data(i64(2))),
		inst.instruction(.Call, types.data(i64(5))),
		inst.instruction(.PopPrint, nil),
		inst.instruction(.Halt, nil),
		inst.instruction(.Add, nil), // Function begins at index 5
		inst.instruction(.Return, nil),
	}
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test8 :: proc() {
	labeled_program: []inst.LabeledInstruction = {
		inst.instruction(.Push, types.data(i64(0))),       
		"loop",
		inst.instruction(.Dup, nil),                        
		inst.instruction(.Push, types.data(i64(3))),        
		inst.instruction(.Eq, nil),                         
		inst.instruction(.JumpIf, types.data("end")),       
		inst.instruction(.Dup, nil),                        
		inst.instruction(.Print, nil),                      
		inst.instruction(.Push, types.data(i64(1))),        
		inst.instruction(.Add, nil),                        
		inst.instruction(.Swap, nil), 
		inst.instruction(.Pop, nil),                        
		inst.instruction(.Jump, types.data("loop")),
		"end",
		inst.instruction(.Pop, nil),                        
		inst.instruction(.Halt, nil),
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM { program = program }
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test9 :: proc() {
	labeled_program: []inst.LabeledInstruction = {
	    inst.instruction(.Push, types.data(i64(123))),     // addr
	    inst.instruction(.Push, types.data(i64(42))),      // value
	    inst.instruction(.Store, nil),                     // memory[42] = 123
	    inst.instruction(.Push, types.data(i64(123))),     // addr
	    inst.instruction(.Load, nil),                      // push memory[42]
	    inst.instruction(.Print, nil),                     // should print 123
	    inst.instruction(.Halt, nil),
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM { program = program }
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test10 :: proc() {
	labeled_program: []inst.LabeledInstruction = {
	    inst.instruction(.Push, types.data(i64(1))),     
	    inst.instruction(.Push, types.data(i64(2))),      
	    inst.instruction(.Push, types.data(i64(3))),      
	    inst.instruction(.Push, types.data(i64(3))),      
	    inst.instruction(.MakeArray, nil),                     
	    inst.instruction(.Push, types.data(i64(1))),     
	    inst.instruction(.GetField, nil),                     
	    inst.instruction(.Print, nil),                     
	    inst.instruction(.Halt, nil),
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM { program = program }
	inst.show_instructions(program)
	vm.run_vm(&state)
}

run_tests :: proc() {
	fmt.println("Test 1:")
	test1()
	fmt.println("\nTest 2:")
	test2()
	fmt.println("\nTest 3:")
	test3()
	fmt.println("\nTest 4:")
	test4()
	fmt.println("\nTest 5:")
	test5()
	fmt.println("\nTest 6:")
	test6()
	fmt.println("\nTest 7:")
	test7()
	fmt.println("\nTest 8:")
	test8()
	fmt.println("\nTest 9:")
	test9()
	fmt.println("\nTest 10:")
	test10()
}

