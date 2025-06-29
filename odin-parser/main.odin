package main

import "core:slice"
import "core:fmt"

// from odin-parser
import "ast"
import "compile"

// from odin-vm
import inst "../odin-vm/instructions"
import "../odin-vm/vm"
import "../odin-vm/types"

main :: proc() {
	test_if_stmt()
	test_loop1()
	test_loop2()
	test_loop3()
	test_func1()
	test_func2()
	test_func3()
}

make_expr_array :: proc(args: ..^ast.Expr) -> [dynamic]^ast.Expr {
	return slice.to_dynamic(args); 
}

make_continue :: proc() -> ^ast.Expr {
	expr := new(ast.Expr)
	expr^ = ast.ContinueExpr{}
	return expr
}

make_break :: proc() -> ^ast.Expr {
	expr := new(ast.Expr)
	expr^ = ast.BreakExpr{}
	return expr
}

make_number :: proc(n: int) -> ^ast.Expr {
	expr := new(ast.Expr);
	expr^ = ast.Number{i64(n)}; 
	return expr;
}

make_ident :: proc(name: string) -> ^ast.Expr {
	expr := new(ast.Expr);
	expr^ = ast.Ident{Name = name};
	return expr;
}

make_binop :: proc(lhs, rhs: ^ast.Expr, op: string) -> ^ast.Expr {
	expr := new(ast.Expr);
	expr^ = ast.BinaryExpr{Left = lhs, Op = op, Right = rhs};
	return expr;
}

make_func_def :: proc(name: string, params: []string, body: []^ast.Expr) -> ^ast.Expr {
	expr := new(ast.Expr);
	p := slice.to_dynamic(params)
	b := slice.clone_to_dynamic(body)
	expr^ = ast.FuncDefExpr{
		Name = name,
		Params = p,
		Body = b,
	};
	return expr;
}

make_call :: proc(name: string, args: ..^ast.Expr) -> ^ast.Expr {
	expr := new(ast.Expr);
	expr^ = ast.CallExpr{
		Name = name,
		Args = slice.clone_to_dynamic(args),
	};
	return expr;
}

make_return :: proc(val: ^ast.Expr) -> ^ast.Expr {
	expr := new(ast.Expr);
	expr^ = ast.ReturnExpr{
		Value = val,
	};
	return expr;
}

make_assign :: proc(name: string, value: ^ast.Expr) -> ^ast.Expr {
	expr := new(ast.Expr);
	expr^ = ast.AssignExpr{Lhs = name, Rhs = value};
	return expr;
}

make_if :: proc(
    cond: ^ast.Expr,
    then_branch: []^ast.Expr,
    elifs: []ast.IfExpr = {},
    else_branch: []^ast.Expr = {},
) -> ^ast.Expr {
    expr := new(ast.Expr);
    expr^ = ast.IfExpr{
        Cond    = cond,
        Then    = slice.to_dynamic(then_branch),
        ElseIfs = slice.to_dynamic(elifs),
        Else    = slice.to_dynamic(else_branch),
    };
    return expr;
}

make_elif :: proc(cond: ^ast.Expr, then_branch: []^ast.Expr) -> ast.IfExpr {
	return ast.IfExpr{
		Cond = cond,
		Then = slice.clone_to_dynamic(then_branch),
	};
}

make_loop :: proc(cond: ^ast.Expr, body: []^ast.Expr) -> ^ast.Expr {
	expr: ^ast.Expr = new(ast.Expr)
	expr^ = ast.LoopExpr{
		Cond = cond,
		Body = slice.clone_to_dynamic(body),
	};
	return expr
}

test_if_stmt :: proc() {
	program: [dynamic]^ast.Expr = {};
	// let x = 1
	assign := make_assign("x", make_number(1));
	// if x == 0: 0
	main_cond := make_binop(make_ident("x"), make_number(0), "==");
	then_branch := make_number(0);
	// else if x == 1: 1
	elif_cond := make_binop(make_ident("x"), make_number(1), "==");
	elif := make_elif(elif_cond, []^ast.Expr{make_number(1)}); // ✅ fixed
	// else: 2
	else_branch := make_number(2);
	// arrays to store them in
	then_arr := []^ast.Expr{then_branch};
	elif_arr := []ast.IfExpr{elif};
	else_arr := []^ast.Expr{else_branch};
	// full if expression
	if_expr := make_if(
		main_cond,
		then_arr,
		elif_arr,
		else_arr,
	);
	append(&program, assign);
	append(&program, if_expr);
	b := compile.emit_program(program);
	compile.emit(&b, .Print, nil);
	compile.emit(&b, .Halt, nil);
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

test_loop1 :: proc() {
	program: [dynamic]^ast.Expr = {};
	// let x = 1
	assign := make_assign("x", make_number(1));
	// loop condition: x < 3
	cond := make_binop(make_ident("x"), make_number(3), "<");
	// loop body:
	body := []^ast.Expr{
		make_ident("x"), // expression result (maybe testing stack behavior)
		make_assign("x",
			make_binop(
				make_ident("x"),
				make_number(1),
				"+"
			)
		),
	};
	loop := make_loop(cond, body);
	// build full program
	append(&program, assign);
	append(&program, loop);
	// compile + emit
	b := compile.emit_program(program);
	compile.emit(&b, .Print, nil);
	compile.emit(&b, .Halt, nil);
	// debug + run
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

test_loop2 :: proc() {
	program: [dynamic]^ast.Expr = {};
	// let x = 1
	assign := make_assign("x", make_number(1));
	// condition: x < 10
	cond := make_binop(make_ident("x"), make_number(10), "<");
	// if x == 5: break
	break_if := make_if(
		make_binop(make_ident("x"), make_number(5), "=="),
		[]^ast.Expr{make_break()},
		[]ast.IfExpr{},
		[]^ast.Expr{},
	);
	// loop body
	body := []^ast.Expr{
		break_if,
		make_ident("x"),
		make_assign("x", make_binop(make_ident("x"), make_number(1), "+")),
	};
	// full loop
	loop := make_loop(cond, body);
	// build program
	append(&program, assign);
	append(&program, loop);
	// compile + emit
	b := compile.emit_program(program);
	compile.emit(&b, .Print, nil); // optional
	compile.emit(&b, .Halt, nil);
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

test_loop3 :: proc() {
	program: [dynamic]^ast.Expr = {};
	// let x = 1
	assign := make_assign("x", make_number(1));
	// loop condition: x < 10
	cond := make_binop(make_ident("x"), make_number(10), "<");
	// if x == 5: { x += 1; continue }
	if_cond := make_binop(make_ident("x"), make_number(5), "==");
	if_then := []^ast.Expr{
		make_assign("x", make_binop(make_ident("x"), make_number(1), "+")),
		make_continue(),
	};
	break_if := make_if(if_cond, if_then, []ast.IfExpr{}, []^ast.Expr{});
	// x += 1
	post_update := make_assign("x", make_binop(make_ident("x"), make_number(1), "+"));
	// loop body
	body := []^ast.Expr{break_if, post_update};
	// full loop
	loop := make_loop(cond, body);
	// build program
	append(&program, assign);
	append(&program, loop);
	// compile + emit
	b := compile.emit_program(program);
	compile.emit(&b, .Load, types.data("x"));
	compile.emit(&b, .Print, nil);
	compile.emit(&b, .Halt, nil);
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

test_func1 :: proc() {
	program: [dynamic]^ast.Expr = {};
	// x := 0
	assign_x := make_assign("x", make_number(0));
	// Function: inc()
	func_body := []^ast.Expr{
		make_assign("x", make_binop(make_ident("x"), make_number(1), "+")),
		make_return(make_ident("x")), // final expression acts as return
	};
	func_def := make_func_def("inc", {}, func_body);
	// Loop condition: x < 3
	loop_cond := make_binop(make_ident("x"), make_number(3), "<");
	// Loop body
	loop_body := []^ast.Expr{
		make_ident("x"),
		make_call("inc", ..[]^ast.Expr{}),
	};
	loop := make_loop(loop_cond, loop_body);
	// Build program
	append(&program, assign_x);
	append(&program, func_def);
	append(&program, loop);
	// Compile
	b := compile.emit_program(program);
	compile.emit(&b, .Print, nil);
	compile.emit(&b, .Halt, nil);
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

test_func2 :: proc() {
	program: [dynamic]^ast.Expr = {};
	// Function: add1(n) { return n + 1 }
	func_body := []^ast.Expr{
		make_return(make_binop(make_ident("n"), make_number(1), "+")),
	};
	func_def := make_func_def("add1", []string{"n"}, func_body);
	// Call: add1(3)
	call := make_call("add1", ..[]^ast.Expr{
		make_number(3),
	});
	// Build and run program
	append(&program, func_def);
	append(&program, call);
	b := compile.emit_program(program);
	compile.emit(&b, .Print, nil);
	compile.emit(&b, .Halt, nil);
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

test_func3 :: proc() {
	program: [dynamic]^ast.Expr = {};
	// Function: sum(a, b) { return a + b }
	func_body := []^ast.Expr{
		make_return(make_binop(make_ident("a"), make_ident("b"), "+")),
	};
	func_def := make_func_def("sum", []string{"a", "b"}, func_body);
	// Call: sum(2, 3)
	call := make_call("sum", ..[]^ast.Expr{
		make_number(2),
		make_number(3),
	});
	// Build and run program
	append(&program, func_def);
	append(&program, call);
	b := compile.emit_program(program);
	compile.emit(&b, .Print, nil);
	compile.emit(&b, .Halt, nil);
	bytecode := inst.resolve_labels(b.code[:]);
	inst.show_instructions(bytecode);
	state := vm.VM{program = bytecode};
	vm.run_vm(&state);
}

