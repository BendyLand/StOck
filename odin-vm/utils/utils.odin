package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:mem"
import "core:mem/virtual"

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
	case .GetField: result = "GetField"
	case .MakeArray: result = "MakeArray"
	case .MakeMap: result = "MakeMap"
	case .SetField: result = "SetField"
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
	case types.ref: result = types.ref
	}
	return result
}

my_assert :: proc(condition: bool, message: string, file: string = #file, line: int = #line) {
	if !condition {
		fmt.eprintfln("Assertion failed on line %d:\nMessage: %s", line, message)
		os.exit(1)
	}
}

// needs to be followed with `defer mem.free_bytes(context.arena.data)`
// ArenaContext :: struct {
//     arena:     ^mem.Arena,
//     memory:    []u8,
//     allocator: mem.Allocator,
// }

// make_arena :: proc(size: int) -> ArenaContext {
//     raw, err := mem.alloc_bytes(size * mem.Megabyte)
//     if err != .None {
//         panic("arena memory alloc failed")
//     }
//     ctx: ArenaContext
//     arena := new(mem.Arena)
//     ctx.memory = raw
//     mem.arena_init(arena, ctx.memory)
//     ctx.arena = arena
//     ctx.allocator = mem.arena_allocator(ctx.arena)
//     return ctx
// }

make_arena :: proc() -> ^virtual.Arena {
	result := new(virtual.Arena)
	err := virtual.arena_init_growing(result)
	if err != nil {
		fmt.eprintfln("Unable to inititialize arena: %v", err)
		os.exit(1)
	}
	return result
}

