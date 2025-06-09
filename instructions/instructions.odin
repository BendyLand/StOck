package instructions

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"

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
    	#partial switch t in entry {
        case string: label_map[t] = i
        case: i += 1
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

