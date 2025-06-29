package ast

import "../../odin-vm/types"

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

