package vm

import "core:fmt"
import "core:os"

import "../ops"
import "../types"
import inst "../instructions"
import "../utils"

MAX_STACK_SIZE :: 256
CALL_STACK_LIMIT :: 64
STACK_LIMIT :: 256

VM :: struct {
    program: []inst.Instruction,
    pc: int,
    sp: int,
    stack: [STACK_LIMIT]types.Data,
    call_stack: [CALL_STACK_LIMIT]int,
    call_sp: int,
    memory: [STACK_LIMIT]types.Data, 
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
		switch op {
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
				types.data(-utils.to_int(val.value)),
				types.data(i64(0)),
				.Add
			) or_continue
			push(vm, neg)
		case .Not: 
			val := pop(vm)
			b := utils.to_bool(val.value)
			push(vm, types.data(!b))
		case .Eq, .Neq, .Lt, .Le, .Gt, .Ge: 
			rhs := pop(vm)
			lhs := pop(vm)
			fmt.printfln("Comparing: %v and %v", lhs.value, rhs.value)
			result := false
			if lhs.kind != rhs.kind {
				fmt.printfln("Invalid comparison: '%v' and '%v'", lhs.value, rhs.value)
				continue
			}
			if lhs.kind == i64 {
				a := utils.to_int(lhs.value)
				b := utils.to_int(rhs.value)
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
				a := utils.to_float(lhs.value)
				b := utils.to_float(rhs.value)
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
			b := utils.to_bool(pop(vm).value)
			a := utils.to_bool(pop(vm).value)
			push(vm, types.data(a && b))
		case .Or: 
			b := utils.to_bool(pop(vm).value)
			a := utils.to_bool(pop(vm).value)
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
			my_assert(utils.to_bool(val.value), utils.to_string(msg.value), line = #line)
		case .Input: 
			buf: [128]u8
			n := os.read(os.stdin, buf[:]) or_continue
			if n > 0 {
				s := string(buf[:n])
				push(vm, types.data(s))
			}
		case .Jump:
			offset := utils.to_int(instr.operand.?.value)
			vm.pc = int(offset)
			continue
		case .JumpIf:
			offset := utils.to_int(instr.operand.?.value)
			cond := utils.to_bool(pop(vm).value)
			if cond {
				vm.pc = int(offset)
				continue
			}
		case .JumpIfNot:
			offset := utils.to_int(instr.operand.?.value)
			cond := utils.to_bool(pop(vm).value)
			if !cond {
				vm.pc = int(offset)
				continue
			}
		case .Call:
			target := utils.to_int(instr.operand.?.value)
			assert(vm.call_sp < CALL_STACK_LIMIT)
			vm.call_stack[vm.call_sp] = vm.pc + 1
			vm.call_sp += 1
			vm.pc = int(target)
			continue
		case .Return:
			assert(vm.call_sp > 0)
			vm.call_sp -= 1
			vm.pc = vm.call_stack[vm.call_sp]
			continue
		case .Store:
		    val := pop(vm)
		    addr := pop(vm)
		    addr_i := utils.to_int(addr.value)
		    vm.memory[addr_i] = val
		case .Load: 
		    addr := pop(vm)
		    addr_i := utils.to_int(addr.value)
		    val: types.Data
		    if addr_i >= len(vm.memory) {
				fmt.printfln("Memory read out of bounds: %d", addr_i)
				val = types.data(nil)
			}
			else {
				val = vm.memory[addr_i]
			}
		    push(vm, val)
		case .Noop: continue
		case .Halt: return
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

handle_values :: proc(a, b: types.Data, op: ops.OpCode) -> (types.Data, bool) {
	if a.kind != b.kind {
		fmt.printfln("Error: mismatched types: '%v' and '%v'", a, b)
		return types.Data{}, false
	}
	res: types.Data
	if a.kind == i64 {
		a_int := utils.to_int(a.value)
		b_int := utils.to_int(b.value)
		ok, temp := handle_opcode(a_int, b_int, op)
		if ok {
			res.value = temp
			res.kind = i64
		}
	}
	else if a.kind == f64 {
		a_float := utils.to_float(a.value)
		b_float := utils.to_float(b.value)
		ok, temp := handle_opcode(a_float, b_float, op)
		if ok {
			res.value = temp
			res.kind = f64
		}
	}
	return res, true
}

