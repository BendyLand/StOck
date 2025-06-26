package tests

import (
	"compiler/ast"
	"compiler/compile"
	"compiler/instructions"
	"compiler/ops"
	"compiler/utils"
	"fmt"
)

func RunTests() {
	fmt.Println("Testing if:")
	testIfStmt()
	fmt.Println("\nTesting loop1:")
	testLoop1()
	fmt.Println("\nTesting loop2:")
	testLoop2()
	fmt.Println("\nTesting loop3")
	testLoop3()
	fmt.Println("\nTesting function1")
	testFunc1()
	fmt.Println("\nTesting function2")
	testFunc2()
	fmt.Println()
}

func testIfStmt() {
	expr := ast.IfExpr{
		Cond: ast.BinaryExpr{
			Left:  ast.Ident{Name: "x"},
			Op:    "==",
			Right: ast.Number{Value: 0},
		},
		Then: []ast.Expr{
			ast.Number{Value: 0},
		},
		ElseIfs: []ast.IfExpr{
			{
				Cond: ast.BinaryExpr{
					Left:  ast.Ident{Name: "x"},
					Op:    "==",
					Right: ast.Number{Value: 1},
				},
				Then: []ast.Expr{
					ast.Number{Value: 1},
				},
			},
		},
		Else: []ast.Expr{
			ast.Number{Value: 2},
		},
	}
	b := compile.BytecodeEmitter{
		Code:   make([]instructions.Instruction, 0),
		Labels: make(map[string]int),
		Patch:  make(map[int]string),
	}
	compile.EmitExpr(&b, expr)
	b.Emit(ops.Print, nil) // final print for top value
	err := b.ResolveLabels()
	if err != nil {
		panic(err)
	}
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testLoop1() {
	loop := ast.LoopExpr{
		Cond: ast.BinaryExpr{
			Left:  ast.Ident{Name: "x"},
			Op:    "<",
			Right: ast.Number{Value: 3},
		},
		Body: []ast.Expr{
			ast.Ident{Name: "x"}, // top of stack is printed
			ast.AssignExpr{
				LHS: "x",
				RHS: ast.BinaryExpr{
					Left:  ast.Ident{Name: "x"},
					Op:    "+",
					Right: ast.Number{Value: 1},
				},
			},
		},
	}
	b := compile.BytecodeEmitter{
		Code:   make([]instructions.Instruction, 0),
		Labels: make(map[string]int),
		Patch:  make(map[int]string),
	}
	compile.EmitExpr(&b, loop)
	b.Emit(ops.Print, nil) // print after loop ends (optional)
	if err := b.ResolveLabels(); err != nil {
		panic(err)
	}
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testLoop2() {
	loop := ast.LoopExpr{
		Cond: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "<", Right: ast.Number{Value: 10}},
		Body: []ast.Expr{
			ast.IfExpr{
				Cond: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "==", Right: ast.Number{Value: 5}},
				Then: []ast.Expr{ast.BreakExpr{}},
			},
			ast.Ident{Name: "x"},
			ast.AssignExpr{
				LHS: "x",
				RHS: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "+", Right: ast.Number{Value: 1}},
			},
		},
	}
	b := compile.BytecodeEmitter{
		Code:   make([]instructions.Instruction, 0),
		Labels: make(map[string]int),
		Patch:  make(map[int]string),
	}
	compile.EmitExpr(&b, loop)
	b.Emit(ops.Print, nil) // print after loop ends (optional)
	if err := b.ResolveLabels(); err != nil {
		panic(err)
	}
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testLoop3() {
	loop := ast.LoopExpr{
		Cond: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "<", Right: ast.Number{Value: 10}},
		Body: []ast.Expr{
			ast.IfExpr{
				Cond: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "==", Right: ast.Number{Value: 5}},
				Then: []ast.Expr{
					ast.ContinueExpr{},
				},
			},
			ast.Ident{Name: "x"},
			ast.AssignExpr{
				LHS: "x",
				RHS: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "+", Right: ast.Number{Value: 1}},
			},
		},
	}
	b := compile.BytecodeEmitter{
		Code:   make([]instructions.Instruction, 0),
		Labels: make(map[string]int),
		Patch:  make(map[int]string),
	}
	compile.EmitExpr(&b, loop)
	b.Emit(ops.Print, nil)
	if err := b.ResolveLabels(); err != nil {
		panic(err)
	}
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testFunc1() {
	// let x = 0
	// def inc() { x = x + 1 }
	// while x < 3 { print(x); inc() }
	program := []ast.Expr{
		ast.AssignExpr{
			LHS: "x",
			RHS: ast.Number{Value: 0},
		},
		ast.FuncDefExpr{
			Name:   "inc",
			Params: []string{}, // no args yet
			Body: []ast.Expr{
				ast.AssignExpr{
					LHS: "x",
					RHS: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "+", Right: ast.Number{Value: 1}},
				},
			},
		},
		ast.LoopExpr{
			Cond: ast.BinaryExpr{Left: ast.Ident{Name: "x"}, Op: "<", Right: ast.Number{Value: 3}},
			Body: []ast.Expr{
				ast.Ident{Name: "x"},
				ast.CallExpr{Name: "inc", Args: []ast.Expr{}},
			},
		},
	}
	b := compile.BytecodeEmitter{
		Code:   make([]instructions.Instruction, 0),
		Labels: make(map[string]int),
		Patch:  make(map[int]string),
	}
	for _, expr := range program {
		switch v := expr.(type) {
		case ast.FuncDefExpr:
			compile.EmitFuncDef(&b, v)
		default:
			compile.EmitExpr(&b, expr)
		}
	}
	b.Emit(ops.Print, nil)
	// Finalize label patching
	if err := b.ResolveLabels(); err != nil {
		panic(err)
	}
	// Dump instructions to stdout
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testFunc2() {
	// let x = 0
	// def inc() { x = x + 1 }
	// while x < 3 { print(x); inc() }
	program := []ast.Expr{
		ast.FuncDefExpr{
			Name:   "add1",
			Params: []string{"n"},
			Body: []ast.Expr{
				ast.BinaryExpr{
					Left:  ast.Ident{Name: "n"},
					Op:    "+",
					Right: ast.Number{Value: 1},
				},
			},
		},
		ast.CallExpr{
			Name: "add1",
			Args: []ast.Expr{ast.Number{Value: 3}},
		},
	}
	b := compile.BytecodeEmitter{
		Code:   make([]instructions.Instruction, 0),
		Labels: make(map[string]int),
		Patch:  make(map[int]string),
	}
	for _, expr := range program {
		switch v := expr.(type) {
		case ast.FuncDefExpr:
			compile.EmitFuncDef(&b, v)
		default:
			compile.EmitExpr(&b, expr)
		}
	}
	// Optional: emit a print if you expect to see function output
	b.Emit(ops.Print, nil)
	// Finalize label patching
	if err := b.ResolveLabels(); err != nil {
		panic(err)
	}
	// Dump instructions to stdout
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}
