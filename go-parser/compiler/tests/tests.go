package tests

import (
	"parser/compiler/ast"
	"parser/compiler/compile"
	"parser/compiler/utils"
	"parser/shared/instructions"
	"parser/shared/ops"
)

func RunTests() {
	// testIfStmt()
	// testLoop1()
	// testLoop2()
	// testLoop3()
	// testFunc1()
	// testFunc2()
	testFunc3()
}

func testIfStmt() {
	assign := ast.AssignExpr{
		LHS: "x",
		RHS: ast.Number{Value: 1},
	}
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

	// ✅ Use the new emitter
	b := compile.BytecodeEmitter{
		Code: make([]instructions.LabeledInstruction, 0),
	}

	// ✅ Emit expressions
	compile.EmitExpr(&b, assign)
	compile.EmitExpr(&b, expr)
	b.Emit(ops.Print, nil) // print result

	// ❌ No more ResolveLabels — Odin does it now
	// ✅ Dump
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testLoop1() {
	program := []ast.Expr{
		ast.AssignExpr{
			LHS:  "x",
			RHS: ast.Number{Value: 1},
		},
		ast.LoopExpr{
			Cond: ast.BinaryExpr{
				Left:  ast.Ident{Name: "x"},
				Op:    "<",
				Right: ast.Number{Value: 3},
			},
			Body: []ast.Expr{
				ast.Ident{Name: "x"},
				ast.AssignExpr{
					LHS: "x",
					RHS: ast.BinaryExpr{
						Left:  ast.Ident{Name: "x"},
						Op:    "+",
						Right: ast.Number{Value: 1},
					},
				},
			},
		},
	}
	b := compile.EmitProgram(program)
	b.Emit(ops.Print, nil)
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testLoop2() {
	program := []ast.Expr{
		ast.AssignExpr{
			LHS:  "x",
			RHS: ast.Number{Value: 1},
		},
		ast.LoopExpr{
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
		},
	}
	b := compile.EmitProgram(program)
	b.Emit(ops.Print, nil) // print after loop ends (optional)
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testLoop3() {
	program := []ast.Expr{
		ast.AssignExpr{
			LHS: "x",
			RHS: ast.Number{Value: 1},
		}, 
		ast.LoopExpr{
			Cond: ast.BinaryExpr{
				Left:  ast.Ident{Name: "x"},
				Op:    "<",
				Right: ast.Number{Value: 10},
			},
			Body: []ast.Expr{
				// if (x == 5) { x += 1; continue }
				ast.IfExpr{
					Cond: ast.BinaryExpr{
						Left:  ast.Ident{Name: "x"},
						Op:    "==",
						Right: ast.Number{Value: 5},
					},
					Then: []ast.Expr{
						ast.AssignExpr{
							LHS: "x",
							RHS: ast.BinaryExpr{
								Left:  ast.Ident{Name: "x"},
								Op:    "+",
								Right: ast.Number{Value: 1},
							},
						},
						ast.ContinueExpr{},
					},
				},
				// x += 1
				ast.AssignExpr{
					LHS: "x",
					RHS: ast.BinaryExpr{
						Left:  ast.Ident{Name: "x"},
						Op:    "+",
						Right: ast.Number{Value: 1},
					},
				},
			},
		},
	}
	b := compile.EmitProgram(program)
	b.Emit(ops.Load, "x")
	b.Emit(ops.Print, nil) // print after loop ends (optional)
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testFunc1() {
	program := []ast.Expr{
		ast.AssignExpr{
			LHS: "x",
			RHS: ast.Number{Value: 0},
		},
		ast.FuncDefExpr{
			Name:   "inc",
			Params: []string{},
			Body: []ast.Expr{
				// x = x + 1
				ast.AssignExpr{
					LHS: "x",
					RHS: ast.BinaryExpr{
						Left:  ast.Ident{Name: "x"},
						Op:    "+",
						Right: ast.Number{Value: 1},
					},
				},
				// return x
				ast.Ident{Name: "x"}, // <--- this pushes the value for Return to use
			},
		},
		ast.LoopExpr{
			Cond: ast.BinaryExpr{
				Left:  ast.Ident{Name: "x"},
				Op:    "<",
				Right: ast.Number{Value: 3},
			},
			Body: []ast.Expr{
				ast.Ident{Name: "x"},
				ast.CallExpr{Name: "inc", Args: []ast.Expr{}},
			},
		},
	}
	// ✅ Emit using the unified entrypoint
	b := compile.EmitProgram(program)
	b.Emit(ops.Print, nil)
	// ✅ Dump for visual inspection
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
			    ast.ReturnExpr{
			        Value: ast.BinaryExpr{
			            Left:  ast.Ident{Name: "n"},
			            Op:    "+",
			            Right: ast.Number{Value: 1},
			        },
			    },
			},
		},
		ast.CallExpr{
			Name: "add1",
			Args: []ast.Expr{ast.Number{Value: 3}},
		},
	}
	b := compile.EmitProgram(program)
	b.Emit(ops.Print, nil)
	// ✅ Dump for visual inspection
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

func testFunc3() {
	// let x = 0
	// def inc() { x = x + 1 }
	// while x < 3 { print(x); inc() }
	program := []ast.Expr{
		ast.FuncDefExpr{
			Name: "sum",
			Params: []string{"a", "b"},
			Body: []ast.Expr{
				ast.ReturnExpr{
					Value: ast.BinaryExpr{
						Left:  ast.Ident{Name: "a"},
						Op:    "+",
						Right: ast.Ident{Name: "b"},
					},
				},
			},
		},
		ast.CallExpr{
			Name: "sum",
			Args: []ast.Expr{ast.Number{Value: 2}, ast.Number{Value: 3}},
		},
	}
	b := compile.EmitProgram(program)
	b.Emit(ops.Print, nil)
	// ✅ Dump for visual inspection
	for i, instr := range b.Code {
		utils.PrettyPrint(i, instr)
	}
}

