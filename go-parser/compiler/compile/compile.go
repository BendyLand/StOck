package compile

import (
	"fmt"
	"compiler/ast"
	inst "compiler/instructions"
	"compiler/ops"
)

type BytecodeEmitter struct {
	Code   []inst.Instruction
	Labels map[string]int // label → instruction index
	Patch  map[int]string // instruction index → label to backpatch
}

// Emit appends a new instruction to the bytecode and returns its index
func (b *BytecodeEmitter) Emit(op ops.OpCode, arg interface{}) int {
	instr := inst.Instruction{
		Opcode:  op,
		Operand: arg,
	}
	b.Code = append(b.Code, instr)
	return len(b.Code) - 1
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
		EmitStmt(b, v)
	case ast.BreakExpr:
		if len(ast.LoopStack) == 0 {
			panic("break used outside of loop")
		}
		b.EmitJump(ops.Jump, ast.LoopStack[len(ast.LoopStack)-1].BreakLabel)
	case ast.ContinueExpr:
		if len(ast.LoopStack) == 0 {
			panic("continue used outside of loop")
		}
		b.EmitJump(ops.Jump, ast.LoopStack[len(ast.LoopStack)-1].ContinueLabel)
	case ast.BlockExpr:
		for _, expr := range v.Body {
			EmitExpr(b, expr)
		}
	case ast.CallExpr:
		for _, arg := range v.Args {
			EmitExpr(b, arg)
		}
		b.Emit(ops.Call, v.Name)
	default:
		panic("unsupported expression type")
	}
}

func EmitFuncDef(b *BytecodeEmitter, fn ast.FuncDefExpr) {
	b.EmitLabel(fn.Name)
	for i := len(fn.Params) - 1; i >= 0; i-- {
		b.Emit(ops.Store, fn.Params[i])
	}
	for _, expr := range fn.Body {
		EmitExpr(b, expr)
	}
	b.Emit(ops.Return, nil)
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

func emitIfBranch(b *BytecodeEmitter, cond ast.Expr, then []ast.Expr, exitLabels *[]string) {
	failLabel := newLabel()
	endLabel := newLabel()
	EmitExpr(b, cond)
	b.EmitJump(ops.JumpIfNot, failLabel)
	for _, expr := range then {
		EmitExpr(b, expr)
	}
	b.EmitJump(ops.Jump, endLabel)
	b.EmitLabel(failLabel)
	*exitLabels = append(*exitLabels, endLabel)
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

func (b *BytecodeEmitter) EmitJump(op ops.OpCode, label string) int {
	i := b.Emit(op, label)
	if b.Patch == nil {
		b.Patch = make(map[int]string)
	}
	b.Patch[i] = label
	return i
}

func (b *BytecodeEmitter) EmitLabel(name string) {
	if b.Labels == nil {
		b.Labels = make(map[string]int)
	}
	b.Labels[name] = len(b.Code)
}

func (b *BytecodeEmitter) ResolveLabels() error {
	for i, label := range b.Patch {
		addr, ok := b.Labels[label]
		if !ok {
			return fmt.Errorf("undefined label: %s", label)
		}
		b.Code[i].Operand = addr
	}
	return nil
}

func EmitLoop(b *BytecodeEmitter, loop ast.LoopExpr) {
	startLabel := newLabel() // where condition is evaluated (continue target)
	endLabel := newLabel()   // where loop ends (break target)

	ast.LoopStack = append(ast.LoopStack, ast.LoopContext{
		ContinueLabel: startLabel,
		BreakLabel:    endLabel,
	})
	defer func() { ast.LoopStack = ast.LoopStack[:len(ast.LoopStack)-1] }() // pop when done

	b.EmitLabel(startLabel)

	EmitExpr(b, loop.Cond)
	b.EmitJump(ops.JumpIfNot, endLabel)

	for _, expr := range loop.Body {
		EmitExpr(b, expr)
	}

	b.EmitJump(ops.Jump, startLabel)
	b.EmitLabel(endLabel)
}

