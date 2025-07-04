package tests

import "core:fmt"
import "core:mem"
import "core:os"
import "core:mem/virtual"

import "../ast"
import "../compile"
import inst "../instructions"
import "../types"
import "../utils"
import "../vm"

run_tests :: proc() {
	arena := utils.make_arena() 
	defer free(arena)
	allocator := virtual.arena_allocator(arena)
	defer virtual.arena_free_all(arena)
	defer virtual.arena_destroy(arena)	
	defer ast.free_allocated_dyn_arrs()
	defer compile.free_allocated_dyn_arrs()
	defer inst.free_allocated_dyn_arrs()
	defer vm.free_allocated_dyn_arrs()

	fmt.println("Test 1:")
	test1(allocator)
	fmt.println("\nTest 2:")
	test2(allocator)
	fmt.println("\nTest 3:")
	test3(allocator)
	fmt.println("\nTest 4:")
	test4(allocator)
	fmt.println("\nTest 5:")
	test5(allocator)
	fmt.println("\nTest 6:")
	test6(allocator)
	fmt.println("\nTest 7:")
	test7(allocator)
	fmt.println("\nTest 8:")
	test8(allocator)
	fmt.println("\nTest 9:")
	test9(allocator)
	fmt.println("\nTest 10:")
	test10(allocator)
	fmt.println("\nTest if statement:")
	test_if_stmt(allocator)
	fmt.println("\nTest loops 1:")
	test_loop1(allocator)
	fmt.println("\nTest loops 2:")
	test_loop2(allocator)
	fmt.println("\nTest loops 3:")
	test_loop3(allocator)
	fmt.println("\nTest functions 1:")
	test_func1(allocator)
	fmt.println("\nTest functions 2:")
	test_func2(allocator)
	fmt.println("\nTest functions 3:")
	test_func3(allocator)
	fmt.println("\nTest booleans 1:")
	test_bool1(allocator)
	fmt.println("\nTest booleans 2:")
	test_bool2(allocator)
	fmt.println("\nTest booleans 3:")
	test_bool3(allocator)
	fmt.println("\nTest and:")
	test_and(allocator)
	fmt.println("\nTest or:")
	test_or(allocator)
	fmt.println("\nTest not:")
	test_not(allocator)
	fmt.println("\nTest strings 1:")
	test_str1(allocator)
	fmt.println("\nTest strings 2:")
	test_str2(allocator)
	fmt.println("\nTest strings 3:")
	test_str3(allocator)
	fmt.println("\nTest strings 4:")
	test_str4(allocator)
	// fmt.println("\nTest strings 5 (should fail):")
	// test_str5()
	// fmt.println("\nTest add string and boolean (should fail):")
	// test_add_str_bool()
	fmt.println()
}

test1 :: proc(arena: mem.Allocator) {
	a := types.data(i64(3), nil)
	b := types.data(i64(4), nil)
	test := types.data(i64(7), nil)
	data := []types.Data{a, b}
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, a, arena),
		inst.instruction(.Push, b, arena),
		inst.instruction(.Add, nil, arena), // 3 + 4
		inst.instruction(.Print, nil, arena),
		inst.instruction(.Push, test, arena),
		inst.instruction(.Eq, nil, arena),
		inst.instruction(.Assert, types.data("result did not match expected value (7)", arena), arena),
		inst.instruction(.Halt, nil, arena), // 7
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test2 :: proc(arena: mem.Allocator) {
	a := types.data(i64(42), nil)
	test := types.data(i64(84), nil)
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, a, arena),
		inst.instruction(.Dup, nil, arena),
		inst.instruction(.Add, nil, arena), // 42 + 42
		inst.instruction(.Print, nil, arena), // expect 84
		inst.instruction(.Push, test, arena),
		inst.instruction(.Eq, nil, arena),
		inst.instruction(.Assert, types.data("result did not match expected value (84)", arena), arena),
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test3 :: proc(arena: mem.Allocator) {
	a := types.data(i64(10), nil)
	b := types.data(i64(20), nil)
	test := types.data(i64(30), nil)
	labeled_program := []^inst.LabeledInstruction{
		inst.instruction(.Push, a, arena),
		inst.instruction(.Push, b, arena),
		inst.instruction(.Swap, nil, arena),
		inst.instruction(.Over, nil, arena),
		inst.instruction(.Add, nil, arena), // 10 + 20
		inst.instruction(.Print, nil, arena), // expect 30
		inst.instruction(.Push, test, arena),
		inst.instruction(.Eq, nil, arena),
		inst.instruction(.Assert, types.data("result did not match expected value (30)", arena), arena),
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test4 :: proc(arena: mem.Allocator) {
	a := types.data(i64(1), nil)
	b := types.data(i64(2), nil)
	c := types.data(i64(3), nil)
	labeled_program := []^inst.LabeledInstruction{
		inst.instruction(.Push, a, arena),
		inst.instruction(.Push, b, arena),
		inst.instruction(.Push, c, arena),
		inst.instruction(.Rot, nil, arena),
		inst.instruction(.Pop, nil, arena), // should pop 1
		inst.instruction(.Print, nil, arena), // should print 3
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test5 :: proc(arena: mem.Allocator) {
	a := types.data(i64(5), nil)
	b := types.data(i64(3), nil)
	c := types.data(i64(2), nil)
	d := types.data(i64(4), nil)
	e := types.data(i64(7), nil)
	labeled_program := []^inst.LabeledInstruction{
		inst.instruction(.Push, a, arena),
		inst.instruction(.Push, a, arena),
		inst.instruction(.Eq, nil, arena), // true
		inst.instruction(.Print, nil, arena),
		inst.instruction(.Assert, types.data("value did not match itself (5)", arena), arena),
		inst.instruction(.Push, b, arena),
		inst.instruction(.Push, c, arena),
		inst.instruction(.Gt, nil, arena), // true
		inst.instruction(.Print, nil, arena),
		inst.instruction(.Assert, types.data("result did not match expected value (3 > 2)", arena), arena),
		inst.instruction(.Push, d, arena),
		inst.instruction(.Push, e, arena),
		inst.instruction(.Lt, nil, arena), // true
		inst.instruction(.Print, nil, arena),
		inst.instruction(.Assert, types.data("result did not match expected value (4 < 7)", arena), arena),
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test6 :: proc(arena: mem.Allocator) {
	a := types.data(i64(7), nil)
	b := types.data(false, nil)
	c := types.data(true, nil)
	labeled_program := []^inst.LabeledInstruction{
		inst.instruction(.Push, a, arena),
		inst.instruction(.Neg, nil, arena),
		inst.instruction(.Print, nil, arena), // expect -7
		inst.instruction(.Push, b, arena),
		inst.instruction(.Not, nil, arena),
		inst.instruction(.Assert, types.data("result did not match expected result (!false)", arena), arena), // should not panic
		inst.instruction(.Push, c, arena),
		inst.instruction(.Push, b, arena),
		inst.instruction(.Or, nil, arena),
		inst.instruction(.Print, nil, arena), // true
		inst.instruction(
			.Assert,
			types.data("result did not match expected result (false || true)", arena),
			arena,
		),
		inst.instruction(.Push, c, arena),
		inst.instruction(.Push, c, arena),
		inst.instruction(.And, nil, arena),
		inst.instruction(.Print, nil, arena), // true
		inst.instruction(
			.Assert,
			types.data("result did not match expected result (true && true)", arena),
			arena,
		),
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test7 :: proc(arena: mem.Allocator) {
	a := types.data(i64(7), nil)
	b := types.data(false, nil)
	c := types.data(true, nil)
	labeled_program := []^inst.LabeledInstruction{
		inst.instruction(.Push, types.data(i64(1), nil), arena),
		inst.instruction(.Push, types.data(i64(2), nil), arena),
		inst.instruction(.Call, types.data(i64(5), nil), arena),
		inst.instruction(.PopPrint, nil, arena),
		inst.instruction(.Halt, nil, arena),
		inst.instruction(.Add, nil, arena), // Function begins at index 5
		inst.instruction(.Return, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test8 :: proc(arena: mem.Allocator) {
	labeled_program: []^inst.LabeledInstruction = {
		inst.instruction(.Push, types.data(i64(0), nil), arena),       
		inst.str_to_labeled_inst("loop", arena),
		inst.instruction(.Dup, nil, arena),                        
		inst.instruction(.Push, types.data(i64(3), nil), arena),        
		inst.instruction(.Eq, nil, arena),                         
		inst.instruction(.JumpIf, types.data("end", arena), arena),       
		inst.instruction(.Dup, nil, arena),                        
		inst.instruction(.Print, nil, arena),                      
		inst.instruction(.Push, types.data(i64(1), nil), arena),        
		inst.instruction(.Add, nil, arena),                        
		inst.instruction(.Swap, nil, arena), 
		inst.instruction(.Pop, nil, arena),                        
		inst.instruction(.Jump, types.data("loop", arena), arena),
		inst.str_to_labeled_inst("end", arena),
		inst.instruction(.Pop, nil, arena),                        
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM { program = program }
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test9 :: proc(arena: mem.Allocator) {
	labeled_program: []^inst.LabeledInstruction = {
		inst.instruction(.Push, types.data(i64(42), nil), arena),   // value
		inst.instruction(.Push, types.data("addr", arena), arena),  // key
		inst.instruction(.Store, nil, arena),                       // memory["addr"] = 42
		inst.instruction(.Load, types.data("addr", arena), arena),  // <- FIXED HERE
		inst.instruction(.Print, nil, arena),                       // should print 42
		inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM { program = program }
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test10 :: proc(arena: mem.Allocator) {
	labeled_program: []^inst.LabeledInstruction = {
	    inst.instruction(.Push, types.data(i64(1), nil), arena),     
	    inst.instruction(.Push, types.data(i64(2), nil), arena),      
	    inst.instruction(.Push, types.data(i64(3), nil), arena),      
	    inst.instruction(.Push, types.data(i64(3), nil), arena),      
	    inst.instruction(.MakeArray, nil, arena),                     
	    inst.instruction(.Push, types.data(i64(1), nil), arena),     
	    inst.instruction(.GetField, nil, arena),                     
	    inst.instruction(.Print, nil, arena),                     
	    inst.instruction(.Halt, nil, arena),
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM { program = program }
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_if_stmt :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1, arena), arena)
	// if x == 0: 0
	main_cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(0, arena), "==", arena)
	then_branch := ast.make_number(0, arena)
	// else if x == 1: 1
	elif_cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(1, arena), "==", arena)
	elif := ast.make_elif(elif_cond, []^ast.Expr{ast.make_number(1, arena)}, arena) 
	// else: 2
	else_branch := ast.make_number(2, arena)
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
		arena,
	)
	append(program, assign)
	append(program, if_expr)
	b := compile.emit_program(program, arena)
	compile.emit(b, .Print, nil, arena)
	compile.emit(b, .Halt, nil, arena)
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_loop1 :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1, arena), arena)
	// loop condition: x < 3
	cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(3, arena), "<", arena)
	// loop body:
	body := []^ast.Expr{
		ast.make_ident("x", arena), // expression result (maybe testing stack behavior)
		ast.make_assign("x",
			ast.make_binop(
				ast.make_ident("x", arena),
				ast.make_number(1, arena),
				"+",
				arena
			),
			arena
		),
	}
	loop := ast.make_loop(cond, body, arena)
	// build full program
	append(program, assign)
	append(program, loop)
	// compile + emit
	b := compile.emit_program(program, arena)
	compile.emit(b, .Print, nil, arena)
	compile.emit(b, .Halt, nil, arena)
	// debug + run
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_loop2 :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1, arena), arena)
	// condition: x < 10
	cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(10, arena), "<", arena)
	// if x == 5: break
	break_if := ast.make_if(
		ast.make_binop(ast.make_ident("x", arena), ast.make_number(5, arena), "==", arena),
		[]^ast.Expr{ast.make_break(arena)},
		[]^ast.Expr{},
		[]^ast.Expr{},
		arena,
	)
	// loop body
	body := []^ast.Expr{
		break_if,
		ast.make_ident("x", arena),
		ast.make_assign("x", ast.make_binop(ast.make_ident("x", arena), ast.make_number(1, arena), "+", arena), arena),
	}
	// full loop
	loop := ast.make_loop(cond, body, arena)
	// build program
	append(program, assign)
	append(program, loop)
	// compile + emit
	b := compile.emit_program(program, arena)
	compile.emit(b, .Print, nil, arena) // optional
	compile.emit(b, .Halt, nil, arena)
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_loop3 :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// let x = 1
	assign := ast.make_assign("x", ast.make_number(1, arena), arena)
	// loop condition: x < 10
	cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(10, arena), "<", arena)
	// if x == 5: { x += 1; continue }
	if_cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(5, arena), "==", arena)
	if_then := []^ast.Expr{
		ast.make_assign("x", ast.make_binop(ast.make_ident("x", arena), ast.make_number(1, arena), "+", arena), arena),
		ast.make_continue(arena),
	}
	break_if := ast.make_if(if_cond, if_then, []^ast.Expr{}, []^ast.Expr{}, arena)
	// x += 1
	post_update := ast.make_assign("x", ast.make_binop(ast.make_ident("x", arena), ast.make_number(1, arena), "+", arena), arena)
	// loop body
	body := []^ast.Expr{break_if, post_update}
	// full loop
	loop := ast.make_loop(cond, body, arena)
	// build program
	append(program, assign)
	append(program, loop)
	// compile + emit
	b := compile.emit_program(program, arena)
	compile.emit(b, .Load, types.data("x", arena), arena)
	compile.emit(b, .Print, nil, arena)
	compile.emit(b, .Halt, nil, arena)
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_func1 :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// x := 0
	assign_x := ast.make_assign("x", ast.make_number(0, arena), arena)
	// Function: inc()
	func_body := []^ast.Expr{
		ast.make_assign("x", ast.make_binop(ast.make_ident("x", arena), ast.make_number(1, arena), "+", arena), arena),
		ast.make_return(ast.make_ident("x", arena), arena), // final expression acts as return
	}
	func_def := ast.make_func_def("inc", {}, func_body, arena)
	// Loop condition: x < 3
	loop_cond := ast.make_binop(ast.make_ident("x", arena), ast.make_number(3, arena), "<", arena)
	// Loop body
	loop_body := []^ast.Expr{
		ast.make_ident("x", arena),
		ast.make_call("inc", []^ast.Expr{}, arena),
	}
	loop := ast.make_loop(loop_cond, loop_body, arena)
	// Build program
	append(program, assign_x)
	append(program, func_def)
	append(program, loop)
	// Compile
	b := compile.emit_program(program, arena)
	compile.emit(b, .Print, nil, arena)
	compile.emit(b, .Halt, nil, arena)
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_func2 :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// Function: add1(n) { return n + 1 }
	func_body := []^ast.Expr{
		ast.make_return(ast.make_binop(ast.make_ident("n", arena), ast.make_number(1, arena), "+", arena), arena),
	}
	func_def := ast.make_func_def("add1", []string{"n"}, func_body, arena)
	// Call: add1(3)
	call := ast.make_call("add1", []^ast.Expr{ast.make_number(3, arena)}, arena)
	// Build and run program
	append(program, func_def)
	append(program, call)
	b := compile.emit_program(program, arena)
	compile.emit(b, .Print, nil, arena)
	compile.emit(b, .Halt, nil, arena)
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_func3 :: proc(arena: mem.Allocator) {
	program := new([dynamic]^ast.Expr)
	program^ = make([dynamic]^ast.Expr, 0)
	defer free(program)
	defer delete(program^)
	// Function: sum(a, b) { return a + b }
	func_body := []^ast.Expr{
		ast.make_return(ast.make_binop(ast.make_ident("a", arena), ast.make_ident("b", arena), "+", arena), arena),
	}
	func_def := ast.make_func_def("sum", []string{"a", "b"}, func_body, arena)
	// Call: sum(2, 3)
	call := ast.make_call("sum", []^ast.Expr{
		ast.make_number(2, arena),
		ast.make_number(3, arena),
	}, arena)
	// Build and run program
	append(program, func_def)
	append(program, call)
	b := compile.emit_program(program, arena)
	compile.emit(b, .Print, nil, arena)
	compile.emit(b, .Halt, nil, arena)
	bytecode := inst.resolve_labels(b.code[:], arena)
	inst.show_instructions(bytecode)
	state := vm.VM{program = bytecode}
	vm.run_vm(&state, arena)
}

test_bool1 :: proc(arena: mem.Allocator) {
	// Push (true)
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data(true, nil), arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_bool2 :: proc(arena: mem.Allocator) {
	// Push (false)
	// Push (false)
	// Eq
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data(false, nil), arena), 
		inst.instruction(.Push, types.data(false, nil), arena), 
		inst.instruction(.Eq, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_bool3 :: proc(arena: mem.Allocator) {
	// Push (true)
	// Push (false)
	// Neq
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data(true, nil), arena), 
		inst.instruction(.Push, types.data(false, nil), arena), 
		inst.instruction(.Neq, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_and :: proc(arena: mem.Allocator) {
	// Push (true)
	// Push (false)
	// And
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data(true, nil), arena), 
		inst.instruction(.Push, types.data(false, nil), arena), 
		inst.instruction(.And, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_or :: proc(arena: mem.Allocator) {
	// Push (false)
	// Push (true)
	// Or
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data(false, nil), arena), 
		inst.instruction(.Push, types.data(true, nil), arena), 
		inst.instruction(.Or, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_not :: proc(arena: mem.Allocator) {
	// Push (false)
	// Not
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data(false, nil), arena), 
		inst.instruction(.Not, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_str1 :: proc(arena: mem.Allocator) {
	// Push ("hello, world")
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data("hello, world", arena), arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_str2 :: proc(arena: mem.Allocator) {
	// Push ("odin")
	// Push ("odin")
	// Eq
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data("odin", arena), arena), 
		inst.instruction(.Push, types.data("odin", arena), arena), 
		inst.instruction(.Eq, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_str3 :: proc(arena: mem.Allocator) {
	// Push ("odin")
	// Push ("zig")
	// Neq
	// Print
	// Halt
	str1 := types.data("odin", arena)
	str2 := types.data("zig", arena)
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, str1, arena), 
		inst.instruction(.Push, str2, arena), 
		inst.instruction(.Neq, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

test_str4 :: proc(arena: mem.Allocator) {
	// Push ("hello, ")
	// Push ("world")
	// Add
	// Print
	// Halt
	str1 := types.data("hello, ", arena)
	str2 := types.data("world", arena)
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, str1, arena), 
		inst.instruction(.Push, str2, arena), 
		inst.instruction(.Add, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

// this test should fail
test_str5 :: proc() {
	// Push ("abc")
	// Push ("def")
	// Sub
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data("abc", arena), arena), 
		inst.instruction(.Push, types.data("def", arena), arena), 
		inst.instruction(.Sub, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

// this test should fail
test_add_str_bool :: proc() {
	// Push ("status: ")
	// Push (true)
	// Add
	// Print
	// Halt
	labeled_program := []^inst.LabeledInstruction {
		inst.instruction(.Push, types.data("status: ", arena), arena), 
		inst.instruction(.Push, types.data(true, arena), arena), 
		inst.instruction(.Add, nil, arena), 
		inst.instruction(.Print, nil, arena), 
		inst.instruction(.Halt, nil, arena), 
	}
	program := inst.resolve_labels(labeled_program, arena)
	state := vm.VM {
		program = program,
	}
	inst.show_instructions(program)
	vm.run_vm(&state, arena)
}

