package instructions

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

import "../ops"
import "../types"
import "../utils"

Instruction :: struct {
	opcode:  ops.OpCode,
	operand: Maybe(types.Data), 
}

LabeledInstruction :: union {
    Instruction,
    string,
}

//TODO: write a "context" struct that includes things like file name, line number, surrounding variables, etc.
//      and add it as a third parameter
instruction :: proc(code: ops.OpCode, val: Maybe(types.Data)) -> Instruction {
	return Instruction{opcode = code, operand = val}
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

show_instructions :: proc(instrs: []Instruction) {
	for instr in instrs {
		print_instruction(instr)
	}
}

resolve_labels :: proc(labeled: []LabeledInstruction) -> []Instruction {
    label_map := map[string]int{}
    program := make([dynamic]Instruction, 0)
    // First pass: record label locations
    i := 0
    for entry in labeled {
    	switch t in entry {
        case string: label_map[t] = i
        case Instruction: i += 1
        }
    }
    // Second pass: replace label operands
    for entry in labeled {
    	switch &t in entry {
    	case string: continue
    	case Instruction:
	        instr := entry
	        if t.operand != nil && t.operand.?.kind == string {
	            label_name := utils.to_string(t.operand.?.value)
	            index := label_map[label_name]
	            t.operand = types.data(i64(index))
	        }
	        append(&program, t)
    	}
    }
    return program[:]
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

parse_instruction :: proc(line: string) -> (Instruction, bool) {
	// Example line: "004: Push 42"
	// Step 1: Skip the index and colon
	colon_index := strings.index(line, ":")
	if colon_index == -1 || colon_index+1 >= len(line) {
		return instruction(.Noop, nil), false
	}
	code_str := strings.trim_space(line[colon_index+1:])
	// Step 2: Split by whitespace
	tokens := strings.fields(code_str)
	if len(tokens) == 0 {
		return instruction(.Noop, nil), true
	}
	// Step 3: Parse opcode
	op_str := tokens[0]
	op := match_op(op_str)
	// Step 4: Parse operand if present
	if len(tokens) == 1 || tokens[1] == "<nil>" {
		return instruction(op, nil), true
	}
	operand_str := tokens[1]
	operand: types.Data
	// Try to parse as integer first
	if val, ok := strconv.parse_i64(operand_str); ok {
		operand = types.data(val)
	}
	else if val, ok := strconv.parse_f64(operand_str); ok {
		operand = types.data(val)
	}
	else {
		// Treat as string (e.g. label names or function names)
		operand = types.data(operand_str)
	}
	return instruction(op, operand), true
}

get_ast :: proc() -> []Instruction {
    buf: [4096]u8 // read in chunks
    result := make([dynamic]Instruction, 0)
    for {
        count, err := os.read(os.stdin, buf[:])
        if err != nil {
        	fmt.eprintln("Read error")
        }
        if count == 0 {
            // stdin is closed — exit loop
            break
        }
        else if count < 0 {
            fmt.println("Read error.")
            break
        }
        // Process the received chunk
        data := string(buf[:count])
        lines: []string
        lines, err = strings.split_lines(data)
        for line in lines {
			fmt.println(line)
        	instruction, ok := parse_instruction(line)
        	if ok { append(&result, instruction) }
        }
    }
    return result[:]
}

