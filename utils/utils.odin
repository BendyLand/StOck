package utils

import "../ops"
import "../types"

to_int :: proc(val: types.DataType) -> i64 {
	result: i64
	#partial switch res in val {
	case i64: result = res
	case: result = 0
	}
	return result
}

to_float :: proc(val: types.DataType) -> f64 {
	result: f64
	#partial switch res in val {
	case f64: result = res
	case: result = 0
	}
	return result
}

to_bool :: proc(val: types.DataType) -> bool {
	result: bool
	#partial switch res in val {
	case bool: result = res
	case: result = false
	}
	return result
}

to_char :: proc(val: types.DataType) -> rune {
	result: rune
	#partial switch res in val {
	case rune: result = res
	case: result = ' ' 
	}
	return result
}

to_string :: proc(val: types.DataType) -> string {
	result: string
	#partial switch res in val {
	case string: result = res
	case: result = ""
	}
	return result
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
	case .Call: result = "Call"
	case .Jump: result = "Jump"
	case .JumpIf: result = "JumpIf"
	case .JumpIfNot: result = "JumpIfNot"
	case .Return: result = "Return"
	case .Store: result = "Store"
	case .Load: result = "Load"
	}
	return result
}

find_data_type :: proc(data: types.DataType) -> typeid {
	result: typeid
	switch t in data {
	case i64: result = i64
	case f64: result = f64
	case rune: result = rune
	case string: result = string
	case bool: result = bool
	}
	return result
}

