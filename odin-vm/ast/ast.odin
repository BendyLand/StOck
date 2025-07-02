package ast

import "core:slice"
import "core:fmt"

import "../types"

allocated_exprs: [dynamic]^Expr
allocated_dyn_arrs: [dynamic]^[dynamic]^Expr
string_arrs: [dynamic]^[dynamic]string

Expr :: union {
	^Number,
	^Ident,
	^BinaryExpr,
	^AssignExpr,
	^IfExpr,
	^LoopExpr,
	^BlockExpr,
	^BreakExpr,
	^ContinueExpr,
	^FuncDefExpr,
	^CallExpr,
	^ReturnExpr,
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
	Then:    ^[dynamic]^Expr,
	ElseIfs: ^[dynamic]^Expr,
	Else:    ^[dynamic]^Expr,
}

FuncDefExpr :: struct {
	Name:   string,
	Params: ^[dynamic]string,
	Body:   ^[dynamic]^Expr,
}

Ident :: struct {
	Name: string,
}

LoopExpr :: struct {
	Cond: ^Expr,
	Body: ^[dynamic]^Expr,   
}

BlockExpr :: struct {
    Body: ^[dynamic]^Expr,
}

LoopContext :: struct {
    ContinueLabel: string,
    BreakLabel:    string,
}

BreakExpr :: struct{}
ContinueExpr :: struct{}

CallExpr :: struct {
	Name: string,
	Args: ^[dynamic]^Expr,
}

ReturnExpr :: struct {
	Value: ^Expr,
}

make_expr_array :: proc(args: []^Expr) -> ^[dynamic]^Expr {
	dyn := slice.clone_to_dynamic(args) 
	arr := new([dynamic]^Expr)
	arr^ = dyn
	append(&allocated_dyn_arrs, arr)
	return arr
}

make_continue :: proc() -> ^Expr {
	expr := new(Expr)
	cont := new(ContinueExpr)
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)cont)
	expr^ = cont
	return expr
}

make_break :: proc() -> ^Expr {
	expr := new(Expr)
	brk := new(BreakExpr)
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)brk)
	expr^ = brk
	return expr
}

make_number :: proc(n: int) -> ^Expr {
	expr := new(Expr)
	num := new(Number)
	num.Value = i64(n)
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)num)
	expr^ = num 
	return expr
}

make_ident :: proc(name: string) -> ^Expr {
	expr := new(Expr)
	id := new(Ident)
	id.Name = name
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)id)
	expr^ = id
	return expr
}

make_binop :: proc(lhs, rhs: ^Expr, op: string) -> ^Expr {
	expr := new(Expr)
	bin := new(BinaryExpr)
	bin.Left = lhs
	bin.Right = rhs
	bin.Op = op
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)bin)
	expr^ = bin
	return expr
}

make_func_def :: proc(name: string, params: []string, body: []^Expr) -> ^Expr {
	expr := new(Expr)
	d1 := slice.clone_to_dynamic(params)
	p := new([dynamic]string)
	p^ = d1
	append(&string_arrs, p)
	d2 := slice.clone_to_dynamic(body)
	b := new([dynamic]^Expr)
	b^ = d2
	append(&allocated_dyn_arrs, b)
	func := new(FuncDefExpr)
	func.Name = name
	func.Params = p
	func.Body = b
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)func)
	expr^ = func
	return expr
}

make_call :: proc(name: string, args: []^Expr) -> ^Expr {
	expr := new(Expr)
	call := new(CallExpr)
	call.Name = name
	dyn := slice.clone_to_dynamic(args)
	call.Args = new([dynamic]^Expr)
	call.Args^ = dyn
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)call)
	append(&allocated_dyn_arrs, call.Args)
	expr^ = call
	return expr
}

make_return :: proc(val: ^Expr) -> ^Expr {
	expr := new(Expr)
	ret := new(ReturnExpr)
	ret.Value = val
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)ret)
	expr^ = ret
	return expr
}

make_assign :: proc(name: string, value: ^Expr) -> ^Expr {
	expr := new(Expr)
	assign := new(AssignExpr)
	assign.Lhs = name
	assign.Rhs = value
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)assign)
	expr^ = assign
	return expr
}

make_if :: proc(
    cond: ^Expr,
    then_branch: []^Expr,
    elifs: []^Expr = {},
    else_branch: []^Expr = {},
) -> ^Expr {
    expr := new(Expr)
    if_expr := new(IfExpr)
    if_expr.Cond = cond
	d1 := slice.clone_to_dynamic(then_branch)
	d2 := slice.clone_to_dynamic(elifs)
	d3 := slice.clone_to_dynamic(else_branch)
    if_expr.Then = new([dynamic]^Expr)
    if_expr.ElseIfs = new([dynamic]^Expr)
    if_expr.Else = new([dynamic]^Expr)
	if_expr.Then^ = d1
	if_expr.ElseIfs^ = d2
	if_expr.Else^ = d3
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)if_expr)
    append(&allocated_dyn_arrs, if_expr.Then)
    append(&allocated_dyn_arrs, if_expr.ElseIfs)
    append(&allocated_dyn_arrs, if_expr.Else)
    expr^ = if_expr
    return expr
}

make_elif :: proc(cond: ^Expr, then_branch: []^Expr) -> ^Expr {
	expr: ^Expr = new(Expr)
	elif := new(IfExpr)
	elif.Cond = cond 
	dyn := slice.clone_to_dynamic(then_branch)
	elif.Then = new([dynamic]^Expr)
	elif.Then^ = dyn
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)elif)
	append(&allocated_dyn_arrs, elif.Then)
	expr^ = elif
	return expr
}

make_loop :: proc(cond: ^Expr, body: []^Expr) -> ^Expr {
	expr: ^Expr = new(Expr)
	loop := new(LoopExpr)
	loop.Cond = cond
	dyn := slice.clone_to_dynamic(body)
	loop.Body = new([dynamic]^Expr)
	loop.Body^ = dyn
	append(&allocated_exprs, expr)
	append(&allocated_exprs, cast(^Expr)loop)
	append(&allocated_dyn_arrs, loop.Body)
	expr^ = loop
	return expr
}

print_expr :: proc(expr: ^Expr) {
	if expr != nil {
		// switch t in expr {
		// case ^AssignExpr: fmt.printfln("AssignExpr: %p", t^)
		// case ^BinaryExpr: fmt.printfln("BinaryExpr: %p", t^)
		// case ^BlockExpr: fmt.printfln("BlockExpr: %p", t^)
		// case ^BreakExpr: fmt.printfln("BreakExpr")
		// case ^CallExpr: fmt.printfln("CallExpr: %p", t^)
		// case ^ContinueExpr: fmt.printfln("ContinueExpr")
		// case ^FuncDefExpr: fmt.printfln("FuncDefExpr: %p", t^)
		// case ^Ident: fmt.printfln("Ident: %p", t^)
		// case ^IfExpr: fmt.printfln("IfExpr: %p", t^)
		// case ^LoopExpr: fmt.printfln("LoopExpr: %p", t^)
		// case ^Number: fmt.printfln("Number: %p", t^)
		// case ^ReturnExpr: fmt.printfln("ReturnExpr: %p", t^)
		// case: fmt.println("Unknown expression type:", expr)
		// }
		switch t in expr {
		case ^AssignExpr: fmt.printfln("AssignExpr: LHS: %p, RHS: %p", t^.Lhs, t^.Rhs)
		case ^BinaryExpr: fmt.printfln("BinaryExpr: Left: %p, Op: %p, Right: %p", t^.Left, t^.Op, t^.Right)
		case ^BlockExpr: fmt.printfln("BlockExpr: Body: %p", t^.Body)
		case ^BreakExpr: fmt.printfln("BreakExpr")
		case ^CallExpr: fmt.printfln("CallExpr: Name: %p, Args: %p", t^.Name, t^.Args)
		case ^ContinueExpr: fmt.printfln("ContinueExpr")
		case ^FuncDefExpr: fmt.printfln("FuncDefExpr: Name: %p, Params: %p, Body: %p", t^.Name, t^.Params, t^.Body)
		case ^Ident: fmt.printfln("Ident: Name: %p", t^.Name)
		case ^IfExpr: fmt.printfln("IfExpr: Cond: %p, Then: %p, ElseIfs: %p, Else: %p", t^.Cond, t^.Then, t^.ElseIfs, t^.Else)
		case ^LoopExpr: fmt.printfln("LoopExpr: Cond: %p, Body: %p", t^.Cond, t^.Body)
		case ^Number: fmt.printfln("Number: Value: %p", t^.Value)
		case ^ReturnExpr: fmt.printfln("ReturnExpr: Value: %p", t^.Value)
		case: fmt.println("Unknown expression type:", expr)
		}
	}
}

free_allocated_dyn_arrs :: proc() {
	for arr in allocated_dyn_arrs {
		if arr != nil {
			delete_dynamic_array(arr^)		
		}
	}
	for arr in string_arrs {
		delete_dynamic_array(arr^)
	}
	delete_dynamic_array(allocated_dyn_arrs)
	delete_dynamic_array(string_arrs)
}

free_allocated_exprs :: proc() {
	for expr in allocated_exprs {
		free(expr)
	}
}

