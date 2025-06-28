package compile

import (
	"fmt"
	"parser/compiler/ast"
	inst "parser/shared/instructions"
	"parser/shared/ops"
)

type BytecodeEmitter struct {
	Code []inst.LabeledInstruction
}

// Emit appends a new instruction to the bytecode and returns its index
func (b *BytecodeEmitter) Emit(op ops.OpCode, operand any) int {
	// Emit a normal instruction
	ins := inst.Instruction{
		Opcode: op,
	}
	if operand != nil {
		ins.Operand = operand
	}
	b.Code = append(b.Code, ins)
	return len(b.Code) - 1
}

func (b *BytecodeEmitter) EmitLabel(name string) {
	b.Code = append(b.Code, name)
}

func (b *BytecodeEmitter) EmitJump(op ops.OpCode, label string) int {
	return b.Emit(op, label) // label stays as string; Odin resolves it
}


func EmitExpr(b *BytecodeEmitter, e ast.Expr) {
	switch v := e.(type) {
	case ast.Number:
		b.Emit(ops.Push, v.Value)
	case ast.Ident:
		b.Emit(ops.Load, v.Name)
	case ast.BinaryExpr:
		EmitExpr(b, v.Left)
		EmitExpr(b, v.Right)
		switch v.Op {
		case "==":
			b.Emit(ops.Eq, nil)
		case "!=":
			b.Emit(ops.Neq, nil)
		case "<":
			b.Emit(ops.Lt, nil)
		case "<=":
			b.Emit(ops.Le, nil)
		case ">":
			b.Emit(ops.Gt, nil)
		case ">=":
			b.Emit(ops.Ge, nil)
		case "+":
			b.Emit(ops.Add, nil)
		case "-":
			b.Emit(ops.Sub, nil)
		case "*":
			b.Emit(ops.Mult, nil)
		case "/":
			b.Emit(ops.Div, nil)
		default:
			panic("unsupported binary operator: " + v.Op)
		}
	case ast.IfExpr:
		EmitIf(b, v)
	case ast.LoopExpr:
		EmitLoop(b, v)
	case ast.AssignExpr:
		EmitExpr(b, v.RHS)
		b.Emit(ops.Push, v.LHS)
		b.Emit(ops.Store, nil)
	case ast.BreakExpr:
		if len(ast.LoopStack) == 0 {
			panic("break used outside of loop")
		}
		b.EmitJump(ops.Jump, ast.LoopStack[len(ast.LoopStack)-1].BreakLabel)
	case ast.ContinueExpr:
		// Get the top loop context
		if len(ast.LoopStack) == 0 {
			panic("Continue statement outside of loop")
		}
		// Emit a jump to the current loop's continue label
		continueLabel := ast.LoopStack[len(ast.LoopStack)-1].ContinueLabel
		b.EmitJump(ops.Jump, continueLabel)
	case ast.BlockExpr:
		for _, expr := range v.Body {
			EmitExpr(b, expr)
		}
	case ast.CallExpr:
		for _, arg := range v.Args {
			EmitExpr(b, arg)
		}
		b.Emit(ops.Call, v.Name)
	case ast.ReturnExpr:
	    EmitExpr(b, v.Value)
	    b.Emit(ops.Return, nil)
	default:
		panic("unsupported expression type")
	}
}

func EmitFuncDef(b *BytecodeEmitter, fn ast.FuncDefExpr) {
	b.EmitLabel(fn.Name)
	// Store each parameter from the stack
	// Assume right now: last pushed arg is top of stack, so reverse store order
	for i := len(fn.Params) - 1; i >= 0; i-- {
		b.Emit(ops.Push, fn.Params[i]) // Push the param name as a string
		b.Emit(ops.Store, nil)         // Store top of stack into param name
	}
	start := len(b.Code)
	for _, expr := range fn.Body {
		EmitExpr(b, expr)
	}
	if len(b.Code) == start || !isLastReturn(b.Code[len(b.Code)-1]) {
		b.Emit(ops.Return, nil)
	}
}

func isLastReturn(i inst.LabeledInstruction) bool {
	switch i.(type) {
	case string:
		return false		
	default:
		return i.(inst.Instruction).Opcode == ops.Return
	}
}

func EmitIf(b *BytecodeEmitter, ifExpr ast.IfExpr) {
	endLabel := newLabel()
	var branchEndLabels []string
	emitIfBranch(b, ifExpr.Cond, ifExpr.Then, &branchEndLabels)
	for _, elif := range ifExpr.ElseIfs {
		emitIfBranch(b, elif.Cond, elif.Then, &branchEndLabels)
	}
	if len(ifExpr.Else) > 0 {
		for _, expr := range ifExpr.Else {
			EmitExpr(b, expr)
		}
	}
	b.EmitLabel(endLabel)
	for _, lbl := range branchEndLabels {
		b.EmitLabel(lbl)
	}
}

func endsInControlFlow(exprs []ast.Expr) bool {
	if len(exprs) == 0 {
		return false
	}
	switch exprs[len(exprs)-1].(type) {
	case ast.ContinueExpr, ast.BreakExpr, ast.ReturnExpr:
		return true
	default:
		return false
	}
}

func emitIfBranch(b *BytecodeEmitter, cond ast.Expr, body []ast.Expr, branchEndLabels *[]string) {
	skipLabel := newLabel()
	EmitExpr(b, cond)
	b.EmitJump(ops.JumpIfNot, skipLabel)
	for _, expr := range body {
		EmitExpr(b, expr)
	}
	if !endsInControlFlow(body) {
		endLabel := newLabel()
		*branchEndLabels = append(*branchEndLabels, endLabel)
		b.EmitJump(ops.Jump, endLabel)
	}
	b.EmitLabel(skipLabel)
}

var labelCounter = 0

func newLabel() string {
	label := fmt.Sprintf("L%d", labelCounter)
	labelCounter++
	return label
}

func EmitStmt(b *BytecodeEmitter, stmt ast.AssignExpr) {
	EmitExpr(b, stmt.RHS)
	b.Emit(ops.Store, stmt.LHS)
}

func EmitLoop(b *BytecodeEmitter, loop ast.LoopExpr) {
	startLabel := newLabel()
	continueLabel := newLabel()
	breakLabel := newLabel()
	ast.LoopStack = append(ast.LoopStack, ast.LoopContext{
		ContinueLabel: continueLabel,
		BreakLabel:    breakLabel,
	})
	defer func() {
		ast.LoopStack = ast.LoopStack[:len(ast.LoopStack)-1]
	}()
	b.EmitLabel(startLabel)
	EmitExpr(b, loop.Cond)
	b.EmitJump(ops.JumpIfNot, breakLabel)
	for _, expr := range loop.Body {
		EmitExpr(b, expr)
	}
	// 🔴 This must exist for `continue` to work!
	b.EmitLabel(continueLabel)
	b.EmitJump(ops.Jump, startLabel)
	b.EmitLabel(breakLabel)
}

func EmitProgram(program []ast.Expr) *BytecodeEmitter {
	b := &BytecodeEmitter{
		Code: make([]inst.LabeledInstruction, 0),
	}
	b.EmitJump(ops.Jump, "__start_main")
	for _, expr := range program {
		if fn, ok := expr.(ast.FuncDefExpr); ok {
			EmitFuncDef(b, fn)
		}
	}
	b.EmitLabel("__start_main")
	for _, expr := range program {
		if _, ok := expr.(ast.FuncDefExpr); !ok {
			EmitExpr(b, expr)
		}
	}
	return b
}

func EmitReturn(b *BytecodeEmitter, r ast.ReturnExpr) {
	if r.Value != nil {
		EmitExpr(b, r.Value)
	}
	b.Emit(ops.Return, nil)
}

