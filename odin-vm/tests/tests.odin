package tests

import "core:fmt"
import "core:mem"
import "core:os"

import "../ast"
import "../compile"
import inst "../instructions"
import "../types"
import "../vm"
import "../utils"

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
	fmt.println("\nTest if statement:")
	test_if_stmt()
	fmt.println("\nTest loops 1:")
	test_loop1()
	fmt.println("\nTest loops 2:")
	test_loop2()
	fmt.println("\nTest loops 3:")
	test_loop3()
	fmt.println("\nTest functions 1:")
	test_func1()
	fmt.println("\nTest functions 2:")
	test_func2()
	fmt.println("\nTest functions 3:")
	test_func3()
	fmt.println("\nTest booleans 1:")
	test_bool1()
	fmt.println("\nTest booleans 2:")
	test_bool2()
	fmt.println("\nTest booleans 3:")
	test_bool3()
	fmt.println("\nTest and:")
	test_and()
	fmt.println("\nTest or:")
	test_or()
	fmt.println("\nTest not:")
	test_not()
	fmt.println("\nTest strings 1:")
	test_str1()
	fmt.println("\nTest strings 2:")
	test_str2()
	fmt.println("\nTest strings 3:")
	test_str3()
	fmt.println("\nTest strings 4:")
	test_str4()
	// fmt.println("\nTest strings 5 (should fail):")
	// test_str5()
	// fmt.println("\nTest add string and boolean (should fail):")
	// test_add_str_bool()
	fmt.println()
}

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
		inst.instruction(.Push, types.data(i64(42))),   // value
		inst.instruction(.Push, types.data("addr")),  // key
		inst.instruction(.Store, nil),                       // memory["addr"] = 42
		inst.instruction(.Load, types.data("addr")),  // <- FIXED HERE
		inst.instruction(.Print, nil),                       // should print 42
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

test_if_stmt :: proc() {
	program: [dynamic]^ast.Expr = {}
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1))
	// if x == 0: 0
	main_cond := ast.make_binop(ast.make_ident("x"), ast.make_number(0), "==")
	then_branch := ast.make_number(0)
	// else if x == 1: 1
	elif_cond := ast.make_binop(ast.make_ident("x"), ast.make_number(1), "==")
	elif := ast.make_elif(elif_cond, []^ast.Expr{ast.make_number(1)}) // ✅ fixed
	// else: 2
	else_branch := ast.make_number(2)
	// arrays to store them in
	then_arr := []^ast.Expr{then_branch}
	elif_arr := []^ast.Expr{elif}
	else_arr := []^ast.Expr{else_branch}
	// full if expression
	if_expr := ast.make_if(
		main_cond,
		then_arr,
		elif_arr,
		else_arr,
	)
	append(&program, assign)
	append(&program, if_expr)
	for p in program {
		ast.print_expr(p)
	}
	b := compile.emit_program(program)
	compile.emit(&b, .Print, nil)
	compile.emit(&b, .Halt, nil)
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_loop1 :: proc() {
	program: [dynamic]^ast.Expr = {}
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1))
	// loop condition: x < 3
	cond := ast.make_binop(ast.make_ident("x"), ast.make_number(3), "<")
	// loop body:
	body := []^ast.Expr{
		ast.make_ident("x"), // expression result (maybe testing stack behavior)
		ast.make_assign("x",
			ast.make_binop(
				ast.make_ident("x"),
				ast.make_number(1),
				"+"
			)
		),
	}
	loop := ast.make_loop(cond, body)
	// build full program
	append(&program, assign)
	append(&program, loop)
	// compile + emit
	b := compile.emit_program(program)
	compile.emit(&b, .Print, nil)
	compile.emit(&b, .Halt, nil)
	// debug + run
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_loop2 :: proc() {
	program: [dynamic]^ast.Expr = {}
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1))
	// condition: x < 10
	cond := ast.make_binop(ast.make_ident("x"), ast.make_number(10), "<")
	// if x == 5: break
	break_if := ast.make_if(
		ast.make_binop(ast.make_ident("x"), ast.make_number(5), "=="),
		[]^ast.Expr{ast.make_break()},
		[]^ast.Expr{},
		[]^ast.Expr{},
	)
	// loop body
	body := []^ast.Expr{
		break_if,
		ast.make_ident("x"),
		ast.make_assign("x", ast.make_binop(ast.make_ident("x"), ast.make_number(1), "+")),
	}
	// full loop
	loop := ast.make_loop(cond, body)
	// build program
	append(&program, assign)
	append(&program, loop)
	// compile + emit
	b := compile.emit_program(program)
	compile.emit(&b, .Print, nil) // optional
	compile.emit(&b, .Halt, nil)
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_loop3 :: proc() {
	program: [dynamic]^ast.Expr = {}
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1))
	// loop condition: x < 10
	cond := ast.make_binop(ast.make_ident("x"), ast.make_number(10), "<")
	// if x == 5: { x += 1; continue }
	if_cond := ast.make_binop(ast.make_ident("x"), ast.make_number(5), "==")
	if_then := []^ast.Expr{
		ast.make_assign("x", ast.make_binop(ast.make_ident("x"), ast.make_number(1), "+")),
		ast.make_continue(),
	}
	break_if := ast.make_if(if_cond, if_then, []^ast.Expr{}, []^ast.Expr{})
	// x += 1
	post_update := ast.make_assign("x", ast.make_binop(ast.make_ident("x"), ast.make_number(1), "+"))
	// loop body
	body := []^ast.Expr{break_if, post_update}
	// full loop
	loop := ast.make_loop(cond, body)
	// build program
	append(&program, assign)
	append(&program, loop)
	// compile + emit
	b := compile.emit_program(program)
	compile.emit(&b, .Load, types.data("x"))
	compile.emit(&b, .Print, nil)
	compile.emit(&b, .Halt, nil)
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_func1 :: proc() {
	program: [dynamic]^ast.Expr = {}
	// x := 0
	assign_x := ast.make_assign("x", ast.make_number(0))
	// Function: inc()
	func_body := []^ast.Expr{
		ast.make_assign("x", ast.make_binop(ast.make_ident("x"), ast.make_number(1), "+")),
		ast.make_return(ast.make_ident("x")), // final expression acts as return
	}
	func_def := ast.make_func_def("inc", {}, func_body)
	// Loop condition: x < 3
	loop_cond := ast.make_binop(ast.make_ident("x"), ast.make_number(3), "<")
	// Loop body
	loop_body := []^ast.Expr{
		ast.make_ident("x"),
		ast.make_call("inc", []^ast.Expr{}),
	}
	loop := ast.make_loop(loop_cond, loop_body)
	// Build program
	append(&program, assign_x)
	append(&program, func_def)
	append(&program, loop)
	// Compile
	b := compile.emit_program(program)
	compile.emit(&b, .Print, nil)
	compile.emit(&b, .Halt, nil)
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_func2 :: proc() {
	program: [dynamic]^ast.Expr = {}
	// Function: add1(n) { return n + 1 }
	func_body := []^ast.Expr{
		ast.make_return(ast.make_binop(ast.make_ident("n"), ast.make_number(1), "+")),
	}
	func_def := ast.make_func_def("add1", []string{"n"}, func_body)
	// Call: add1(3)
	call := ast.make_call("add1", []^ast.Expr{
		ast.make_number(3),
	})
	// Build and run program
	append(&program, func_def)
	append(&program, call)
	b := compile.emit_program(program)
	compile.emit(&b, .Print, nil)
	compile.emit(&b, .Halt, nil)
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_func3 :: proc() {
	program: [dynamic]^ast.Expr = {}
	// Function: sum(a, b) { return a + b }
	func_body := []^ast.Expr{
		ast.make_return(ast.make_binop(ast.make_ident("a"), ast.make_ident("b"), "+")),
	}
	func_def := ast.make_func_def("sum", []string{"a", "b"}, func_body)
	// Call: sum(2, 3)
	call := ast.make_call("sum", []^ast.Expr{
		ast.make_number(2),
		ast.make_number(3),
	})
	// Build and run program
	append(&program, func_def)
	append(&program, call)
	b := compile.emit_program(program)
	compile.emit(&b, .Print, nil)
	compile.emit(&b, .Halt, nil)
	bytecode := inst.resolve_labels(b.code[:])
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state)
}

test_bool1 :: proc() {
	// Push (true)
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data(true)), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_bool2 :: proc() {
	// Push (false)
	// Push (false)
	// Eq
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data(false)), 
		inst.instruction(.Push, types.data(false)), 
		inst.instruction(.Eq, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_bool3 :: proc() {
	// Push (true)
	// Push (false)
	// Neq
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data(true)), 
		inst.instruction(.Push, types.data(false)), 
		inst.instruction(.Neq, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_and :: proc() {
	// Push (true)
	// Push (false)
	// And
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data(true)), 
		inst.instruction(.Push, types.data(false)), 
		inst.instruction(.And, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_or :: proc() {
	// Push (false)
	// Push (true)
	// Or
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data(false)), 
		inst.instruction(.Push, types.data(true)), 
		inst.instruction(.Or, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_not :: proc() {
	// Push (false)
	// Not
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data(false)), 
		inst.instruction(.Not, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_str1 :: proc() {
	// Push ("hello, world")
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data("hello, world")), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_str2 :: proc() {
	// Push ("odin")
	// Push ("odin")
	// Eq
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data("odin")), 
		inst.instruction(.Push, types.data("odin")), 
		inst.instruction(.Eq, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_str3 :: proc() {
	// Push ("odin")
	// Push ("zig")
	// Neq
	// Print
	// Halt
	str1 := types.data("odin")
	str2 := types.data("zig")
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, str1), 
		inst.instruction(.Push, str2), 
		inst.instruction(.Neq, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

test_str4 :: proc() {
	// Push ("hello, ")
	// Push ("world")
	// Add
	// Print
	// Halt
	str1 := types.data("hello, ")
	str2 := types.data("world")
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, str1), 
		inst.instruction(.Push, str2), 
		inst.instruction(.Add, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

// this test should fail
test_str5 :: proc() {
	// Push ("abc")
	// Push ("def")
	// Sub
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data("abc")), 
		inst.instruction(.Push, types.data("def")), 
		inst.instruction(.Sub, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

// this test should fail
test_add_str_bool :: proc() {
	// Push ("status: ")
	// Push (true)
	// Add
	// Print
	// Halt
	labeled_program := []inst.LabeledInstruction {
		inst.instruction(.Push, types.data("status: ")), 
		inst.instruction(.Push, types.data(true)), 
		inst.instruction(.Add, nil), 
		inst.instruction(.Print, nil), 
		inst.instruction(.Halt, nil), 
	}
	program := inst.resolve_labels(labeled_program)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state)
}

