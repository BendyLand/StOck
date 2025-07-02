package compile

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:slice"

import inst "../instructions"
import "../ast"
import "../ops"
import "../types"

BytecodeEmitter :: struct {
    code: [dynamic]inst.LabeledInstruction,
}

label_counter: int = 0
new_label :: proc() -> string {
	builder := strings.builder_make()
	label := fmt.sbprintfln(&builder, "L%d", label_counter)
    label_counter += 1
    return label
}

emit :: proc(b: ^BytecodeEmitter, opcode: ops.OpCode, operand: Maybe(types.Data)) -> int {
	instr: inst.LabeledInstruction = inst.instruction(opcode, operand)
	append(&b.code, instr)
	return len(b.code) - 1
}

emit_label :: proc(b: ^BytecodeEmitter, label: string) {
	append(&b.code, label)
}

emit_jump :: proc(b: ^BytecodeEmitter, opcode: ops.OpCode, label: string) -> int {
	operand := types.data(label)
	return emit(b, opcode, operand)
}

emit_push_i64 :: proc(b: ^BytecodeEmitter, val: i64) {
	data := types.data(val)
	emit(b, .Push, data)
}

emit_expr :: proc(b: ^BytecodeEmitter, e: ^ast.Expr) {
    if e == nil {
    	fmt.printfln("b = %v\ne = %v", b, e)
        panic("emit_expr called with nil expression pointer")
    }
    #partial switch t in e {
    case ^ast.Number:
        emit(b, .Push, types.data(t.Value))
    case ^ast.Ident:
    	name := types.data(t.Name)
        emit(b, .Load, name)
    case ^ast.BinaryExpr:
        emit_expr(b, t.Left)
        emit_expr(b, t.Right)
        opcode: ops.OpCode
        switch t.Op {
            case "==": opcode = .Eq
            case "!=": opcode = .Neq
            case "<" : opcode = .Lt
            case "<=": opcode = .Le
            case ">" : opcode = .Gt
            case ">=": opcode = .Ge
            case "+" : opcode = .Add
            case "-" : opcode = .Sub
            case "*" : opcode = .Mult
            case "/" : opcode = .Div
            case:
            	builder := strings.builder_make()
            	err_msg := fmt.sbprintfln(&builder, "Unsupported binary op: %s", t.Op)
            	strings.builder_destroy(&builder)
            	panic(err_msg)
        }
        emit(b, opcode, nil)
    case ^ast.AssignExpr:
        emit_expr(b, t.Rhs)
        //FIX leak
        name := types.data(t.Lhs)
        emit(b, .Push, name)
        emit(b, .Store, nil)
    case ^ast.CallExpr:
        for i := len(t.Args)-1; i >= 0; i -= 1 {
            emit_expr(b, t.Args[i])
        }
        //FIX leak
        name := types.data(t.Name)
        emit(b, .Call, name)
    case ^ast.ReturnExpr:
        emit_expr(b, t.Value)
        emit(b, .Return, nil)
    case ^ast.IfExpr:
	    emit_if_expr(b, t)
	case ^ast.LoopExpr:
	    emit_loop_expr(b, t)
	case ^ast.BreakExpr:
	    if len(loop_stack) == 0 {
	        panic("break outside loop")
	    }
	    //FIX leak
	    label := loop_stack[len(loop_stack)-1].BreakLabel
	    emit_jump(b, .Jump, label)
	case ^ast.ContinueExpr:
	    if len(loop_stack) == 0 {
	        panic("continue outside loop")
	    }
	    //FIX leak
	    label := loop_stack[len(loop_stack)-1].ContinueLabel
	    emit_jump(b, .Jump, label)
	case ^ast.BlockExpr:
	    for expr in t.Body {
	        emit_expr(b, expr)
	    }
    case:
	    fmt.println(t)
        panic("Unsupported expression in emit_expr")
    }
}

emit_if_branch :: proc(
	b: ^BytecodeEmitter,
	cond: ^ast.Expr,
	body: ^[dynamic]^ast.Expr,
	branch_end_labels: ^[dynamic]string,
) {
	skip_label := new_label()
	emit_expr(b, cond)
	emit_jump(b, .JumpIfNot, skip_label)
	for expr in body {
		emit_expr(b, expr)
	}
	if !ends_in_control_flow(body) {
		end_label := new_label()
		append(branch_end_labels, end_label)
		emit_jump(b, .Jump, end_label)
	}
	emit_label(b, skip_label)
}

emit_if_expr :: proc(b: ^BytecodeEmitter, t: ^ast.IfExpr) {
	end_label := new_label()
	branch_end_labels: [dynamic]string = make([dynamic]string, 0)
	emit_if_branch(b, t.Cond, t.Then, &branch_end_labels)
	for elif in t.ElseIfs {
		#partial switch t in elif {
		case ^ast.IfExpr:
			emit_if_branch(b, t.Cond, t.Then, &branch_end_labels)
		}
	}
	for expr in t.Else {
		emit_expr(b, expr)
	}
	for lbl in branch_end_labels {
		emit_label(b, lbl)
	}
	emit_label(b, end_label)
}

loop_stack: [dynamic]ast.LoopContext
emit_loop_expr :: proc(b: ^BytecodeEmitter, t: ^ast.LoopExpr) {
    start_label := new_label()
    continue_label := new_label()
    break_label := new_label()
    append(&loop_stack, ast.LoopContext{
        ContinueLabel = continue_label,
        BreakLabel = break_label,
    })
    defer {
	    if len(loop_stack) > 0 {
	        loop_stack = slice.clone_to_dynamic(loop_stack[0:len(loop_stack)-1])
	    }
	    else {
	        panic("loop_stack underflow during defer")
	    }
	}
    emit_label(b, start_label)
    emit_expr(b, t.Cond)
    emit_jump(b, .JumpIfNot, break_label)
    for expr in t.Body {
        emit_expr(b, expr)
    }
    emit_label(b, continue_label)
    emit_jump(b, .Jump, start_label)
    emit_label(b, break_label)
}

emit_func_def :: proc(b: ^BytecodeEmitter, t: ^ast.FuncDefExpr) {
    emit_label(b, t.Name)
    for i := len(t.Params) - 1; i >= 0; i -= 1 {
        emit(b, .Push, types.data(t.Params[i]))
        emit(b, .Store, nil)
    }
    for expr in t.Body {
	    if expr == nil {
	        panic("nil expression in function body")
	    }
	    emit_expr(b, expr)
	}
    emit(b, .Return, nil)
}

emit_program :: proc(program: [dynamic]^ast.Expr) -> BytecodeEmitter {
	b := BytecodeEmitter{}
	// Jump past top-level functions to __start_main
	emit_jump(&b, .Jump, "__start_main")
	// Emit function definitions first
	for expr in program {
		#partial switch t in expr^ {
		case ^ast.FuncDefExpr:
			emit_func_def(&b, t)
		}
	}
	// Start of "main" body
	emit_label(&b, "__start_main")
	// Emit all non-function top-level expressions
	for expr in program {
		#partial switch t in expr^ {
		case ^ast.FuncDefExpr: continue
		case:
			emit_expr(&b, expr)
		}
	}
	return b
}

ends_in_control_flow :: proc(exprs: ^[dynamic]^ast.Expr) -> bool {
    if len(exprs) == 0 {
        return false
    }
    #partial switch t in exprs[len(exprs)-1]^ {
    case ^ast.ContinueExpr, ^ast.BreakExpr, ^ast.ReturnExpr:
        return true
    case:
        return false
    }
}

