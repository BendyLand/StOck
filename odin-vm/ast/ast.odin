package ast

import "core:fmt"
import "core:mem"
import "core:slice"

import "../types"

allocated_expr_arrs := make([dynamic]^[dynamic]^Expr, 0)
allocated_str_arrs := make([dynamic]^[dynamic]string, 0)

Expr :: union {
	Number,
	Ident,
	BinaryExpr,
	AssignExpr,
	IfExpr,
	LoopExpr,
	BlockExpr,
	BreakExpr,
	ContinueExpr,
	FuncDefExpr,
	CallExpr,
	ReturnExpr,
}

Number :: struct {
	Value: types.DataType,
}

BinaryExpr :: struct {
	Left:  ^Expr,
	Op:    string,
	Right: ^Expr,
}

AssignExpr :: struct {
	Lhs: string,
	Rhs: ^Expr,
}

IfExpr :: struct {
	Cond:    ^Expr,
	Then:    [dynamic]^Expr,
	ElseIfs: [dynamic]^Expr,
	Else:    [dynamic]^Expr,
}

FuncDefExpr :: struct {
	Name:   string,
	Params: [dynamic]string,
	Body:   [dynamic]^Expr,
}

Ident :: struct {
	Name: string,
}

LoopExpr :: struct {
	Cond: ^Expr,
	Body: [dynamic]^Expr,
}

BlockExpr :: struct {
	Body: [dynamic]^Expr,
}

LoopContext :: struct {
	ContinueLabel: string,
	BreakLabel:    string,
}

BreakExpr :: struct {}
ContinueExpr :: struct {}

CallExpr :: struct {
	Name: string,
	Args: [dynamic]^Expr,
}

ReturnExpr :: struct {
	Value: ^Expr,
}

make_expr_array :: proc(args: []^Expr) -> [dynamic]^Expr {
	result := new([dynamic]^Expr)
	result^ = slice.clone_to_dynamic(args)
	append(&allocated_expr_arrs, result)
	return result^
}

make_continue :: proc(arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = ContinueExpr{}
	return expr
}

make_break :: proc(arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = BreakExpr{}
	return expr
}

make_number :: proc(n: int, arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = Number{i64(n)}
	return expr
}

make_ident :: proc(name: string, arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = Ident {
		Name = name,
	}
	return expr
}

make_binop :: proc(lhs, rhs: ^Expr, op: string, arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = BinaryExpr {
		Left  = lhs,
		Op    = op,
		Right = rhs,
	}
	return expr
}

make_func_def :: proc(
	name: string,
	params: []string,
	body: []^Expr,
	arena: mem.Allocator,
) -> ^Expr {
	expr := new(Expr, arena)
	p := new([dynamic]string)
	b := new([dynamic]^Expr)
	p^ = slice.clone_to_dynamic(params)
	b^ = slice.clone_to_dynamic(body)
	append(&allocated_str_arrs, p)
	append(&allocated_expr_arrs, b)
	expr^ = FuncDefExpr {
		Name   = name,
		Params = p^,
		Body   = b^,
	}
	return expr
}

make_call :: proc(name: string, args: []^Expr, arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	a := new([dynamic]^Expr)
	a^ = slice.clone_to_dynamic(args, arena)
	append(&allocated_expr_arrs, a)
	expr^ = CallExpr {
		Name = name,
		Args = a^,
	}
	return expr
}

make_return :: proc(val: ^Expr, arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = ReturnExpr {
		Value = val,
	}
	return expr
}

make_assign :: proc(name: string, value: ^Expr, arena: mem.Allocator) -> ^Expr {
	expr := new(Expr, arena)
	expr^ = AssignExpr {
		Lhs = name,
		Rhs = value,
	}
	return expr
}

make_if :: proc(
	cond: ^Expr,
	then_branch: []^Expr,
	elifs: []^Expr = {},
	else_branch: []^Expr = {},
	arena: mem.Allocator,
) -> ^Expr {
	expr := new(Expr, arena)
	t := new([dynamic]^Expr)
	ei := new([dynamic]^Expr)
	e := new([dynamic]^Expr)
	t^ = slice.clone_to_dynamic(then_branch)
	ei^ = slice.clone_to_dynamic(elifs)
	e^ = slice.clone_to_dynamic(else_branch)
	append(&allocated_expr_arrs, t)
	append(&allocated_expr_arrs, ei)
	append(&allocated_expr_arrs, e)
	expr^ = IfExpr {
		Cond    = cond,
		Then    = t^,
		ElseIfs = ei^,
		Else    = e^,
	}
	return expr
}

make_elif :: proc(cond: ^Expr, then_branch: []^Expr, arena: mem.Allocator) -> ^Expr {
	expr: ^Expr = new(Expr, arena)
	t := new([dynamic]^Expr)
	t^ = slice.clone_to_dynamic(then_branch)
	append(&allocated_expr_arrs, t)
	expr^ = IfExpr {
		Cond = cond,
		Then = t^,
	}
	return expr
}

make_loop :: proc(cond: ^Expr, body: []^Expr, arena: mem.Allocator) -> ^Expr {
	expr: ^Expr = new(Expr, arena)
	b := new([dynamic]^Expr)
	b^ = slice.clone_to_dynamic(body, arena)
	append(&allocated_expr_arrs, b)
	expr^ = LoopExpr {
		Cond = cond,
		Body = b^,
	}
	return expr
}

free_allocated_dyn_arrs :: proc() {
	for arr in allocated_expr_arrs {
		delete(arr^)
		free(arr)
	}
	for arr in allocated_str_arrs {
		delete(arr^)
		free(arr)
	}
	delete(allocated_expr_arrs)
	delete(allocated_str_arrs)
}

