package instructions

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

import "../ops"
import "../types"
import "../utils"

allocated_instr_arrs := make([dynamic]^[dynamic]^Instruction)
allocated_l_instr_arrs := make([dynamic]^[dynamic]^LabeledInstruction)

Instruction :: struct {
	opcode:  ops.OpCode,
	operand: Maybe(types.Data), 
}

LabeledInstruction :: union {
    ^Instruction,
    string,
}

//TODO: write a "context" struct that includes things like file name, line number, surrounding variables, etc.
//      and add it as a third parameter
instruction :: proc(code: ops.OpCode, val: Maybe(types.Data), arena: mem.Allocator) -> ^LabeledInstruction {
	res := new(LabeledInstruction, arena)
	inst := new(Instruction, arena)
	inst.opcode = code
	inst.operand = val
	res^ = inst
	return res
}

str_to_labeled_inst :: proc(text: string, arena: mem.Allocator) -> ^LabeledInstruction {
	res := new(LabeledInstruction, arena)
	res^ = text
	return res
}

print_instruction :: proc(instruction: Instruction) {
	data := instruction.operand
	switch x in data {
	case nil:
		fmt.printfln("\t%v", instruction.opcode)
	case types.Data:
		fmt.printfln("\t%v (%v)", instruction.opcode, x.value)
	}
}

show_instructions :: proc(instrs: ^[dynamic]^Instruction) {
	for instr in instrs {
		if instr != nil {
			print_instruction(instr^)
		}
	}
}

match_op :: proc(op_str: string) -> ops.OpCode {
	result: ops.OpCode
	switch op_str {
	case "Push":      result = .Push
	case "Pop":       result = .Pop
	case "PopPrint":  result = .PopPrint
	case "Print":     result = .Print
	case "Add":       result = .Add
	case "Sub":       result = .Sub
	case "Mul":       result = .Mult
	case "Div":       result = .Div
	case "Neg":       result = .Neg
	case "Eq":        result = .Eq
	case "Neq":       result = .Neq
	case "Gt":        result = .Gt
	case "Lt":        result = .Lt
	case "And":       result = .And
	case "Or":        result = .Or
	case "Not":       result = .Not
	case "Dup":       result = .Dup
	case "Swap":      result = .Swap
	case "Over":      result = .Over
	case "Rot":       result = .Rot
	case "Jump":      result = .Jump
	case "JumpIf":    result = .JumpIf
	case "JumpIfNot": result = .JumpIfNot
	case "Store":     result = .Store
	case "Load":      result = .Load
	case "Call":      result = .Call
	case "Return":    result = .Return
	case "Assert":    result = .Assert
	case "Halt":      result = .Halt
	case "Nop":       result = .Noop
	case:             result = .Noop 
	}
	return result
}

parse_instruction :: proc(line: string, arena: mem.Allocator) -> (^LabeledInstruction, bool) {
	// Step 1: Skip the index and colon
	colon_index := strings.index(line, ":")
	if colon_index == -1 || colon_index+1 >= len(line) {
		res := instruction(.Noop, nil, arena)
		return res, false
	}
	code_str := strings.trim_space(line[colon_index+1:])
	// ✅ New: handle raw labels (no opcode, e.g., "my_label")
	if !strings.contains(code_str, " ") {
		// If there's no space, it's likely a label (e.g., "L1", "__start_main", "func_name")
		res := new(LabeledInstruction, arena)
		res^ = LabeledInstruction(code_str)
		return res, true
	}
	// Step 2: Split by whitespace
	tokens := strings.fields(code_str)
	if len(tokens) == 0 {
		res := instruction(.Noop, nil, arena)
		return res, true
	}
	// Step 3: Parse opcode
	op_str := tokens[0]
	op := match_op(op_str)
	// Step 4: Parse operand if present
	if len(tokens) == 1 || tokens[1] == "<nil>" {
		res := instruction(op, nil, arena)
		return res, true
	}
	operand_str := tokens[1]
	operand: types.Data
	if val, ok := strconv.parse_i64(operand_str); ok {
		operand = types.data(val, nil)
	}
	else if val, ok := strconv.parse_f64(operand_str); ok {
		operand = types.data(val, nil)
	}
	else {
		// Label or symbolic name (e.g., var or function)
		operand = types.data(operand_str, arena)
	}
	res := instruction(op, operand, arena)
	return res, true
}

get_ast_from_go :: proc(arena: mem.Allocator) -> ^[dynamic]^Instruction {
	buf: [4096]u8
	result := new([dynamic]^LabeledInstruction)
	result^ = make([dynamic]^LabeledInstruction, 0)
	append(&allocated_l_instr_arrs, result)
	for {
		count, err := os.read(os.stdin, buf[:])
		if err != nil {
			fmt.eprintln("Read error")
		}
		if count <= 0 {
			break
		}
		data := string(buf[:count])
		lines, _ := strings.split_lines(data)
		for line in lines {
			instr, ok := parse_instruction(line, arena)
			if ok {
				append(result, instr)
			}
		}
	}
	resolved := resolve_labels(result[:], arena)
	return resolved
}

resolve_labels :: proc(instructions: []^LabeledInstruction, arena: mem.Allocator) -> ^[dynamic]^Instruction {
    label_map := map[string]int{}
    defer delete(label_map)
    resolved := new([dynamic]^Instruction)
    resolved^ = make([dynamic]^Instruction, 0)
    append(&allocated_instr_arrs, resolved)
    // 1. First pass: record label positions
    for i in 0..<len(instructions) {
        switch t in instructions[i] {
        case string:
        	label_map[t] = len(resolved)
        case ^Instruction:
        	append(resolved, t)
        }
    }
    // 2. Second pass: patch label operands
    for i in 0..<len(resolved) {
        instr := resolved[i]
        if instr.operand != nil && instr.operand.?.kind == string {
            label_name := instr.operand.?.value.(string)
            // Only patch if this opcode expects a label
            #partial switch instr.opcode {
            case .Jump, .JumpIf, .JumpIfNot, .Call:
                if val, ok := label_map[label_name]; ok {
                    resolved[i].operand = types.data(i64(val), nil)
                }
                else {
                    fmt.eprintfln("Unknown label: %s", label_name)
                    os.exit(1)
                }
            }
        }
    }
    return resolved
}

free_allocated_dyn_arrs :: proc() {
	for arr in allocated_instr_arrs {
		delete(arr^)
		free(arr)
	}
	for arr in allocated_l_instr_arrs {
		delete(arr^)
		free(arr)
	}
	delete(allocated_instr_arrs)
	delete(allocated_l_instr_arrs)
}

