package ast

type Expr any

type Number struct {
	Value int
}

type Ident struct {
	Name string
}

type BinaryExpr struct {
	Left  Expr
	Op    string
	Right Expr
}

type AssignExpr struct {
	LHS string
	RHS Expr
}

type IfExpr struct {
	Cond    Expr       
	Then    []Expr     
	ElseIfs []IfExpr   
	Else    []Expr     
}

type LoopExpr struct {
	Cond Expr     
	Body []Expr   
}

type LoopContext struct {
    ContinueLabel string
    BreakLabel    string
}
var LoopStack []LoopContext

type BreakExpr struct{}
type ContinueExpr struct{}

type BlockExpr struct {
    Body []Expr
}

type FuncDefExpr struct {
	Name   string
	Params []string
	Body   []Expr
}

type CallExpr struct {
	Name string
	Args []Expr
}

type ReturnExpr struct {
	Value Expr 
}

