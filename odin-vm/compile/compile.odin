package compile

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strconv"
import "core:strings"

import "../ast"
import inst "../instructions"
import "../ops"
import "../types"

allocated_str_arrs := make([dynamic]^[dynamic]string)
allocated_labeled_inst_arrs := make([dynamic]^[dynamic]^inst.LabeledInstruction)

BytecodeEmitter :: struct {
	code: [dynamic]^inst.LabeledInstruction,
}

label_counter: int = 0
new_label :: proc(arena: mem.Allocator) -> string {
	builder := strings.builder_make(arena)
	label := fmt.sbprintfln(&builder, "L%d", label_counter)
	label_counter += 1
	return label
}

emit :: proc(
	b: ^BytecodeEmitter,
	opcode: ops.OpCode,
	operand: Maybe(types.Data),
	arena: mem.Allocator,
) -> int {
	if !slice.contains(allocated_labeled_inst_arrs[:], &b.code) {
		append(&allocated_labeled_inst_arrs, &b.code)
	}
	instr := inst.instruction(opcode, operand, arena)
	append(&b.code, instr)
	return len(b.code) - 1
}

emit_label :: proc(b: ^BytecodeEmitter, label: string, arena: mem.Allocator) {
	append(&b.code, inst.str_to_labeled_inst(label, arena))
}

emit_jump :: proc(
	b: ^BytecodeEmitter,
	opcode: ops.OpCode,
	label: string,
	arena: mem.Allocator,
) -> int {
	operand := types.data(label, arena)
	return emit(b, opcode, operand, arena)
}

emit_push_i64 :: proc(b: ^BytecodeEmitter, val: i64, arena: mem.Allocator) {
	data := types.data(val, nil)
	emit(b, .Push, data, arena)
}

emit_expr :: proc(b: ^BytecodeEmitter, e: ^ast.Expr, arena: mem.Allocator) {
	if e == nil {
		fmt.printfln("b = %v\ne = %v", b, e)
		panic("emit_expr called with nil expression pointer")
	}
	#partial switch t in e {
	case ast.Number:
		emit(b, .Push, types.data(t.Value, nil), arena)
	case ast.Ident:
		emit(b, .Load, types.data(t.Name, arena), arena)
	case ast.BinaryExpr:
		emit_expr(b, t.Left, arena)
		emit_expr(b, t.Right, arena)
		opcode: ops.OpCode
		switch t.Op {
		case "==":
			opcode = .Eq
		case "!=":
			opcode = .Neq
		case "<":
			opcode = .Lt
		case "<=":
			opcode = .Le
		case ">":
			opcode = .Gt
		case ">=":
			opcode = .Ge
		case "+":
			opcode = .Add
		case "-":
			opcode = .Sub
		case "*":
			opcode = .Mult
		case "/":
			opcode = .Div
		case:
			builder := strings.builder_make()
			err_msg := fmt.sbprintfln(&builder, "Unsupported binary op: %s", t.Op)
			strings.builder_destroy(&builder)
			panic(err_msg)
		}
		emit(b, opcode, nil, arena)
	case ast.AssignExpr:
		emit_expr(b, t.Rhs, arena)
		emit(b, .Push, types.data(t.Lhs, arena), arena)
		emit(b, .Store, nil, arena)
	case ast.CallExpr:
		for i := len(t.Args) - 1; i >= 0; i -= 1 {
			emit_expr(b, t.Args[i], arena)
		}
		emit(b, .Call, types.data(t.Name, arena), arena)
	case ast.ReturnExpr:
		emit_expr(b, t.Value, arena)
		emit(b, .Return, nil, arena)
	case ast.IfExpr:
		emit_if_expr(b, t, arena)
	case ast.LoopExpr:
		emit_loop_expr(b, t, arena)
	case ast.BreakExpr:
		if len(loop_stack) == 0 {
			panic("break outside loop")
		}
		emit_jump(b, .Jump, loop_stack[len(loop_stack) - 1].BreakLabel, arena)
	case ast.ContinueExpr:
		if len(loop_stack) == 0 {
			panic("continue outside loop")
		}
		emit_jump(b, .Jump, loop_stack[len(loop_stack) - 1].ContinueLabel, arena)
	case ast.BlockExpr:
		for expr in t.Body {
			emit_expr(b, expr, arena)
		}
	case:
		panic("Unsupported expression in emit_expr")
	}
}

emit_if_branch :: proc(
	b: ^BytecodeEmitter,
	cond: ^ast.Expr,
	body: [dynamic]^ast.Expr,
	branch_end_labels: ^[dynamic]string,
	arena: mem.Allocator,
) {
	skip_label := new_label(arena)
	emit_expr(b, cond, arena)
	emit_jump(b, .JumpIfNot, skip_label, arena)
	for expr in body {
		emit_expr(b, expr, arena)
	}
	if !ends_in_control_flow(body) {
		end_label := new_label(arena)
		append(branch_end_labels, end_label)
		emit_jump(b, .Jump, end_label, arena)
	}
	emit_label(b, skip_label, arena)
}

emit_if_expr :: proc(b: ^BytecodeEmitter, t: ast.IfExpr, arena: mem.Allocator) {
	end_label := new_label(arena)
	branch_end_labels := new([dynamic]string)
	branch_end_labels^ = make([dynamic]string, 0)
	append(&allocated_str_arrs, branch_end_labels)
	emit_if_branch(b, t.Cond, t.Then, branch_end_labels, arena)
	for elif in t.ElseIfs {
		emit_if_branch(b, elif.(ast.IfExpr).Cond, elif.(ast.IfExpr).Then, branch_end_labels, arena)
	}
	for expr in t.Else {
		emit_expr(b, expr, arena)
	}
	for lbl in branch_end_labels {
		emit_label(b, lbl, arena)
	}
	emit_label(b, end_label, arena)
}

allocated_loop_stacks := new([dynamic]^[dynamic]^ast.LoopContext)
loop_stack := new([dynamic]^ast.LoopContext)
emit_loop_expr :: proc(b: ^BytecodeEmitter, t: ast.LoopExpr, arena: mem.Allocator) {
	if !slice.contains(allocated_loop_stacks[:], loop_stack) {
		append(allocated_loop_stacks, loop_stack)
	}
	start_label := new_label(arena)
	continue_label := new_label(arena)
	break_label := new_label(arena)
	ctx := new(ast.LoopContext, arena)
	ctx^ = ast.LoopContext {
		ContinueLabel = continue_label,
		BreakLabel    = break_label,
	}
	append(loop_stack, ctx)
	defer {
		if len(loop_stack) > 0 {
			new_stack := new([dynamic]^ast.LoopContext)
			new_stack^ = slice.clone_to_dynamic(loop_stack[0:len(loop_stack) - 1])
			append(allocated_loop_stacks, new_stack)
			loop_stack = new_stack
		}
		else {
			panic("loop_stack underflow during defer")
		}
	}
	emit_label(b, start_label, arena)
	emit_expr(b, t.Cond, arena)
	emit_jump(b, .JumpIfNot, break_label, arena)
	for expr in t.Body {
		emit_expr(b, expr, arena)
	}
	emit_label(b, continue_label, arena)
	emit_jump(b, .Jump, start_label, arena)
	emit_label(b, break_label, arena)
}

emit_func_def :: proc(b: ^BytecodeEmitter, t: ast.FuncDefExpr, arena: mem.Allocator) {
	emit_label(b, t.Name, arena)
	for i := len(t.Params) - 1; i >= 0; i -= 1 {
		emit(b, .Push, types.data(t.Params[i], arena), arena)
		emit(b, .Store, nil, arena)
	}
	for expr in t.Body {
		if expr == nil {
			panic("nil expression in function body")
		}
		emit_expr(b, expr, arena)
	}
	emit(b, .Return, nil, arena)
}

emit_program :: proc(program: ^[dynamic]^ast.Expr, arena: mem.Allocator) -> ^BytecodeEmitter {
	b := new(BytecodeEmitter)
	// Jump past top-level functions to __start_main
	emit_jump(b, .Jump, "__start_main", arena)
	// Emit function definitions first
	for expr in program {
		#partial switch t in expr^ {
		case ast.FuncDefExpr:
			emit_func_def(b, t, arena)
		}
	}
	// Start of "main" body
	emit_label(b, "__start_main", arena)
	// Emit all non-function top-level expressions
	for expr in program {
		#partial switch t in expr^ {
		case ast.FuncDefExpr:
			continue
		case ast.LoopExpr:
			emit_expr(b, expr, arena)
		case:
			emit_expr(b, expr, arena)
		}
	}
	return b
}

ends_in_control_flow :: proc(exprs: [dynamic]^ast.Expr) -> bool {
	if len(exprs) == 0 {
		return false
	}
	#partial switch t in exprs[len(exprs) - 1]^ {
	case ast.ContinueExpr, ast.BreakExpr, ast.ReturnExpr:
		return true
	case:
		return false
	}
}

free_allocated_dyn_arrs :: proc() {
	for arr in allocated_str_arrs {
		delete(arr^)
		free(arr)
	}
	for arr in allocated_loop_stacks {
		delete(arr^)
		free(arr)
	}
	for arr in allocated_labeled_inst_arrs {
		delete(arr^)
		free(arr)
	}
	delete(allocated_str_arrs)
	delete(allocated_labeled_inst_arrs)
	delete(allocated_loop_stacks^)
	free(allocated_loop_stacks)
}

