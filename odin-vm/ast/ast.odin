package ast

import "core:slice"

import "../types"

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
	ElseIfs: [dynamic]IfExpr,
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

BreakExpr :: struct{}
ContinueExpr :: struct{}

CallExpr :: struct {
	Name: string,
	Args: [dynamic]^Expr,
}

ReturnExpr :: struct {
	Value: ^Expr,
}


make_expr_array :: proc(args: ..^Expr) -> [dynamic]^Expr {
	return slice.to_dynamic(args) 
}

make_continue :: proc() -> ^Expr {
	expr := new(Expr)
	expr^ = ContinueExpr{}
	return expr
}

make_break :: proc() -> ^Expr {
	expr := new(Expr)
	expr^ = BreakExpr{}
	return expr
}

make_number :: proc(n: int) -> ^Expr {
	expr := new(Expr)
	expr^ = Number{i64(n)} 
	return expr
}

make_ident :: proc(name: string) -> ^Expr {
	expr := new(Expr)
	expr^ = Ident{Name = name}
	return expr
}

make_binop :: proc(lhs, rhs: ^Expr, op: string) -> ^Expr {
	expr := new(Expr)
	expr^ = BinaryExpr{Left = lhs, Op = op, Right = rhs}
	return expr
}

make_func_def :: proc(name: string, params: []string, body: []^Expr) -> ^Expr {
	expr := new(Expr)
	p := slice.to_dynamic(params)
	b := slice.clone_to_dynamic(body)
	expr^ = FuncDefExpr{
		Name = name,
		Params = p,
		Body = b,
	}
	return expr
}

make_call :: proc(name: string, args: ..^Expr) -> ^Expr {
	expr := new(Expr)
	expr^ = CallExpr{
		Name = name,
		Args = slice.clone_to_dynamic(args),
	}
	return expr
}

make_return :: proc(val: ^Expr) -> ^Expr {
	expr := new(Expr)
	expr^ = ReturnExpr{
		Value = val,
	}
	return expr
}

make_assign :: proc(name: string, value: ^Expr) -> ^Expr {
	expr := new(Expr)
	expr^ = AssignExpr{Lhs = name, Rhs = value}
	return expr
}

make_if :: proc(
    cond: ^Expr,
    then_branch: []^Expr,
    elifs: []IfExpr = {},
    else_branch: []^Expr = {},
) -> ^Expr {
    expr := new(Expr)
    expr^ = IfExpr{
        Cond    = cond,
        Then    = slice.to_dynamic(then_branch),
        ElseIfs = slice.to_dynamic(elifs),
        Else    = slice.to_dynamic(else_branch),
    }
    return expr
}

make_elif :: proc(cond: ^Expr, then_branch: []^Expr) -> IfExpr {
	return IfExpr{
		Cond = cond,
		Then = slice.clone_to_dynamic(then_branch),
	}
}

make_loop :: proc(cond: ^Expr, body: []^Expr) -> ^Expr {
	expr: ^Expr = new(Expr)
	expr^ = LoopExpr{
		Cond = cond,
		Body = slice.clone_to_dynamic(body),
	}
	return expr
}

