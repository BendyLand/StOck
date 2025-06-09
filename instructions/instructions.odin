package instructions

import "core:fmt"
import "core:strings"
import "core:strconv"

import "../ops"
import "../types"

Instruction :: struct {
	opcode:  ops.OpCode,
	operand: Maybe(types.Data), 
}

//TODO: write a "context" struct that includes things like file name, line number, surrounding variables, etc.
//      and add it as a third parameter
instruction :: proc(code: ops.OpCode, val: Maybe(types.Data)) -> Instruction {
	return Instruction{opcode = code, operand = val}
}

opcode_to_string :: proc(code: ops.OpCode) -> string {
	result: string
	switch code {
    case .Push: result = "Push"
    case .Pop: result = "Pop"
    case .Dup: result = "Dup"
    case .Swap: result = "Swap"
    case .Over: result = "Over"
    case .Rot: result = "Rot"
    case .Input: result = "Input"
    case .Assert: result = "Assert"
    case .Noop: result = "Noop"
	case .Add: result = "Add"
	case .Sub: result = "Sub"
	case .Mult: result = "Mult"
	case .Div: result = "Div"
	case .Mod: result = "Mod"
	case .PopPrint: result = "PopPrint" 
	case .Print: result = "Print"
	case .Halt: result = "Halt"
	case .Neg: result = "Neg"
	case .Eq: result = "Eq"
	case .Neq: result = "Neq"
	case .Gt: result = "Gt"
	case .Ge: result = "Ge"
	case .Lt: result = "Lt"
	case .Le: result = "Le"
	case .Not: result = "Not"
	case .And: result = "And"
	case .Or: result = "Or"
	}
	return result
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

