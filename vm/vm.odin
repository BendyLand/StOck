package vm

import "core:fmt"
import "core:os"

import "../ops"
import "../types"
import inst "../instructions"

MAX_STACK_SIZE :: 256

VM :: struct {
    stack: [MAX_STACK_SIZE]types.Data,
    sp:    int,
    pc:    int,
    program: []inst.Instruction,
}

push :: proc(vm: ^VM, val: types.Data) {
	vm.stack[vm.sp] = val
	vm.sp += 1
}

pop :: proc(vm: ^VM) -> types.Data {
	assert(vm.sp > 0, "Nothing to pop.")
	vm.sp -= 1
	return vm.stack[vm.sp]
}

my_assert :: proc(condition: bool, message: string, file: string = #file, line: int = #line) {
	if !condition {
		fmt.eprintfln("Assertion failed on line %d:\nMessage: %s", line, message)
		os.exit(1)
	}
}

/* 
    // Jump(offset: int), // these require an int argument
    // JumpIf(offset: int),
    // JumpIfNot(offset: int),
    // Store(slot_id: int),
    // Load(slot_id: int),
*/

run_vm :: proc(vm: ^VM) {
	for vm.pc < len(vm.program) {
		instr := vm.program[vm.pc]
		op := instr.opcode
		#partial switch op {
		case .Push:
			val := instr.operand.?
			push(vm, val)
		case .Pop:
			pop(vm)
		case .Dup: 
			val := vm.stack[vm.sp - 1]
			push(vm, val)
		case .Swap: 
			assert(vm.sp >= 2)
			a := pop(vm)
			b := pop(vm)
			push(vm, a)
			push(vm, b)
		case .Over: 
			assert(vm.sp >= 2)
			val := vm.stack[vm.sp - 2]
			push(vm, val)
		case .Rot: 
			assert(vm.sp >= 3)
			a := pop(vm)
			b := pop(vm)
			c := pop(vm)
			push(vm, b)
			push(vm, a)
			push(vm, c)
		case .Neg: 
			val := pop(vm)
			neg := handle_values(
				types.data(-to_int(val.value)),
				types.data(i64(0)),
				.Add
			) or_continue
			push(vm, neg)
		case .Not: 
			val := pop(vm)
			b := to_bool(val.value)
			push(vm, types.data(!b))
		case .Eq, .Neq, .Lt, .Le, .Gt, .Ge: 
			rhs := pop(vm)
			lhs := pop(vm)
			result := false
			if lhs.kind != rhs.kind {
				fmt.printfln("Invalid comparison: '%v' and '%v'", lhs.value, rhs.value)
				continue
			}
			if lhs.kind == i64 {
				a := to_int(lhs.value)
				b := to_int(rhs.value)
				#partial switch op {
				case .Eq:  result = a == b
				case .Neq: result = a != b
				case .Lt:  result = a < b
				case .Le:  result = a <= b
				case .Gt:  result = a > b
				case .Ge:  result = a >= b
				}
			}
			else if lhs.kind == f64 {
				a := to_float(lhs.value)
				b := to_float(rhs.value)
				#partial switch op {
				case .Eq:  result = a == b
				case .Neq: result = a != b
				case .Lt:  result = a < b
				case .Le:  result = a <= b
				case .Gt:  result = a > b
				case .Ge:  result = a >= b
				}
			}
			push(vm, types.data(result))
		case .And: 
			b := to_bool(pop(vm).value)
			a := to_bool(pop(vm).value)
			push(vm, types.data(a && b))
		case .Or: 
			b := to_bool(pop(vm).value)
			a := to_bool(pop(vm).value)
			push(vm, types.data(a || b))
		case .Add, .Sub, .Mult, .Div, .Mod: 
			rhs := pop(vm)
			lhs := pop(vm)
			res := handle_values(lhs, rhs, op) or_continue
			push(vm, res)
		case .PopPrint: 
			val := pop(vm)
			fmt.println(val.value)
		case .Print: 
			val := vm.stack[vm.sp - 1]
			fmt.println(val.value)
		case .Assert: 
			msg := instr.operand.? or_else types.data("Assert failed; no custom message included at call site.")
			val := pop(vm)
			my_assert(to_bool(val.value), to_string(msg.value), line = #line)
		case .Input: 
			buf: [128]u8
			n := os.read(os.stdin, buf[:]) or_continue
			if n > 0 {
				s := string(buf[:n])
				push(vm, types.data(s))
			}
		case .Noop: continue
		case .Halt: break
		}
		vm.pc += 1
	}
}

handle_int_opcode :: proc(a, b: i64, op: ops.OpCode) -> (bool, i64) {
	result: i64
	#partial switch op {
	case .Add:
		result = a + b
	case .Sub:
		result = a - b
	case .Mult:
		result = a * b
	case .Div:
		result = a / b
	case .Mod:
		result = a % b
	case:
		return false, i64(0)
	}
	return true, result
}

handle_float_opcode :: proc(a, b: f64, op: ops.OpCode) -> (bool, f64) {
	result: f64
	#partial switch op {
	case .Add:
		result = a + b
	case .Sub:
		result = a - b
	case .Mult:
		result = a * b
	case .Div:
		result = a / b
	case .Mod:
		result = f64(i64(a) % i64(b))
	case:
		return false, f64(0)
	}
	return true, result
}

handle_opcode :: proc{handle_int_opcode, handle_float_opcode}

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

handle_values :: proc(a, b: types.Data, op: ops.OpCode) -> (types.Data, bool) {
	if a.kind != b.kind {
		fmt.printfln("Error: mismatched types: '%v' and '%v'", a, b)
		return types.Data{}, false
	}
	res: types.Data
	if a.kind == i64 {
		a_int := to_int(a.value)
		b_int := to_int(b.value)
		ok, temp := handle_opcode(a_int, b_int, op)
		if ok {
			res.value = temp
			res.kind = i64
		}
	}
	else if a.kind == f64 {
		a_float := to_float(a.value)
		b_float := to_float(b.value)
		ok, temp := handle_opcode(a_float, b_float, op)
		if ok {
			res.value = temp
			res.kind = f64
		}
	}
	return res, true
}

