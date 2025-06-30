package vm

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"

import "../heap"
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
    sp_stack: [CALL_STACK_LIMIT]int,
    call_sp: int,
    memory: [STACK_LIMIT]types.Data, 
    heap: heap.Heap,
    symbols: map[string]int, 
    next_slot: int, 
}

push :: proc(vm: ^VM, val: types.Data) {
	vm.stack[vm.sp] = val
	vm.sp += 1
}

pop :: proc(vm: ^VM, arena: mem.Allocator) -> types.Data {
	assert_msg(vm.sp > 0, "Nothing to pop.", vm, arena)
	vm.sp -= 1
	return vm.stack[vm.sp]
}

run_vm :: proc(vm: ^VM) {
	ctx := utils.make_arena(8)
	defer mem.free_bytes(ctx.arena.data)
	for vm.pc < len(vm.program) {
		instr := vm.program[vm.pc]
		op := instr.opcode
		switch op {
		case .Push:
			val := instr.operand.?
			push(vm, val)
		case .Pop:
			pop(vm, ctx.allocator)
		case .Dup: 
			val := vm.stack[vm.sp - 1]
			push(vm, val)
		case .Swap: 
			assert(vm.sp >= 2)
			a := pop(vm, ctx.allocator)
			b := pop(vm, ctx.allocator)
			push(vm, a)
			push(vm, b)
		case .Over: 
			assert(vm.sp >= 2)
			val := vm.stack[vm.sp - 2]
			push(vm, val)
		case .Rot: 
			assert(vm.sp >= 3)
			a := pop(vm, ctx.allocator)
			b := pop(vm, ctx.allocator)
			c := pop(vm, ctx.allocator)
			push(vm, b)
			push(vm, a)
			push(vm, c)
		case .Neg: 
			val := pop(vm, ctx.allocator)
			neg := handle_values(
				types.data(-utils.to_int(val.value), nil),
				types.data(i64(0), nil),
				.Add, 
				ctx.allocator
			) or_continue
			push(vm, neg)
		case .Not: 
			val := pop(vm, ctx.allocator)
			b := utils.to_bool(val.value)
			push(vm, types.data(!b, nil))
		case .Eq, .Neq, .Lt, .Le, .Gt, .Ge: 
			rhs := pop(vm, ctx.allocator)
			lhs := pop(vm, ctx.allocator)
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
			else if lhs.kind == string {
				a := utils.to_string(lhs.value)
				b := utils.to_string(rhs.value)
				result = a == b
			}
			else if lhs.kind == bool {
				a := lhs.value.(bool)
				b := rhs.value.(bool)
				result = a == b
			}
			push(vm, types.data(result, nil))
		case .And: 
			b := utils.to_bool(pop(vm, ctx.allocator).value)
			a := utils.to_bool(pop(vm, ctx.allocator).value)
			push(vm, types.data(a && b, nil))
		case .Or: 
			b := utils.to_bool(pop(vm, ctx.allocator).value)
			a := utils.to_bool(pop(vm, ctx.allocator).value)
			push(vm, types.data(a || b, nil))
		case .Add, .Sub, .Mult, .Div, .Mod: 
			rhs := pop(vm, ctx.allocator)
			lhs := pop(vm, ctx.allocator)
			res := handle_values(lhs, rhs, op, ctx.allocator) or_continue
			push(vm, res)
		case .PopPrint: 
			val := pop(vm, ctx.allocator)
			fmt.println(val.value)
		case .Print: 
			val := vm.stack[vm.sp - 1]
			fmt.println(val.value)
		case .Assert: 
			msg := instr.operand.? or_else types.data("Assert failed; no custom message included at call site.", ctx.allocator)
			val := pop(vm, ctx.allocator)
			utils.my_assert(utils.to_bool(val.value), utils.to_string(msg.value), line = #line)
		case .Input: 
			buf: [128]u8
			n := os.read(os.stdin, buf[:]) or_continue
			if n > 0 {
				s := string(buf[:n])
				push(vm, types.data(s, ctx.allocator))
			}
		case .Jump:
			offset := utils.to_int(instr.operand.?.value)
			vm.pc = int(offset)
			continue
		case .JumpIf:
			offset := utils.to_int(instr.operand.?.value)
			cond := utils.to_bool(pop(vm, ctx.allocator).value)
			if cond {
				vm.pc = int(offset)
				continue
			}
		case .JumpIfNot:
			offset := utils.to_int(instr.operand.?.value)
			cond := utils.to_bool(pop(vm, ctx.allocator).value)
			if !cond {
				vm.pc = int(offset)
				continue
			}
		case .Call:
		    operand := instr.operand.?
		    addr := operand.value.(i64)
		    vm.call_stack[vm.call_sp] = vm.pc + 1
		    vm.call_sp += 1
		    vm.pc = int(addr)
		    continue
		case .Return:
		    if vm.call_sp == 0 {
		        panic("Call stack underflow")
		    }
		    vm.call_sp -= 1
		    vm.pc = vm.call_stack[vm.call_sp]
		    continue
		case .Store: 
		    name := pop(vm, ctx.allocator)     // value to store
		    val := pop(vm, ctx.allocator)    // variable name as string
		    if name.kind != string {
		        fmt.println("Invalid store target: not a string")
		        fmt.println(name, name.kind)
		        break
		    }
		    key := utils.to_string(name.value) 
		    slot, ok := vm.symbols[key]
		    if !ok {
		        slot = vm.next_slot
		        vm.symbols[key] = slot
		        vm.next_slot += 1
		    }
		    vm.memory[slot] = val
		case .Load: 
		    assert_msg(instr.operand != nil, "Load with nil operand", vm, ctx.allocator)
		    addr_name := utils.to_string(instr.operand.?.value)
		    addr_i := vm.symbols[addr_name]
		    assert_msg(addr_i < len(vm.memory), "Load out of bounds", vm, ctx.allocator)
		    val := vm.memory[addr_i]
		    push(vm, val)
		case .MakeArray:
			count := utils.to_int(pop(vm, ctx.allocator).value)
			elems := make([dynamic]types.Data, count)
			for i := count - 1; i >= 0; i -= 1 {
			    elems[i] = pop(vm, ctx.allocator)
			}
			id := vm.heap.next_id
			vm.heap.next_id += 1
			vm.heap.objects[id] = elems
			push(vm, types.data(i64(id), nil)) // push ref
		case .MakeMap:
		    id := vm.heap.next_id
		    vm.heap.next_id += 1
		    vm.heap.objects[id] = heap.Map{}
		    push(vm, types.data(i64(id), nil)) // store the object ID as an i64
		case .GetField:
			head := pop(vm, ctx.allocator).value
			ref := utils.to_int(pop(vm, ctx.allocator).value)
			obj := vm.heap.objects[ref]
			#partial switch x in obj {
			case heap.Map:
				key := utils.to_string(head)
			    val := x[key] or_else types.data(nil, nil)
			    push(vm, val)
			case heap.Struct:
				key := utils.to_string(head)
			    val := x[key] or_else types.data(nil, nil)
			    push(vm, val)
			case [dynamic]types.Data:
		        index := utils.to_int(head)
		        if index < 0 || index >= i64(len(x)) {
		            fmt.eprintfln("Array index out of bounds: %d", index)
		            os.exit(1)
		        }
		        push(vm, x[index])
			case:
			    fmt.eprintln("Invalid field access")
			    os.exit(1)
			}
		case .SetField: {
		    value := pop(vm, ctx.allocator)
		    key := utils.to_string(pop(vm, ctx.allocator).value)
		    ref := utils.to_int(pop(vm, ctx.allocator).value)
		    // Fetch the union object (by copy)
		    obj, ok := vm.heap.objects[ref]
		    if !ok {
		        fmt.eprintfln("Invalid heap reference: %d", ref)
		        os.exit(1)
		    }
		    // Extract the map so we can mutate it
		    map_val := obj.(heap.Map)
		    if map_val == nil {
		        fmt.eprintfln("Object at %d is not a map", ref)
		        os.exit(1)
		    }
		    // Perform mutation
		    map_val[key] = value
		    // Write the mutated map back into the union and update the heap
		    vm.heap.objects[ref] = map_val
		}
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

handle_values :: proc(a, b: types.Data, op: ops.OpCode, allocator: mem.Allocator) -> (types.Data, bool) {
	if a.kind != b.kind {
		fmt.printfln("Error: mismatched types: '%v' and '%v'", a, b)
		return types.Data{}, false
	}
	res: types.Data
	if a.kind == string && b.kind == string && op == .Add {
		a := utils.to_string(a.value)
		b := utils.to_string(b.value)
		builder := strings.builder_make()
		defer strings.builder_destroy(&builder)
		result := fmt.sbprintf(&builder, "%s%s", a, b)
		return types.data(result, allocator), true
	}
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
	else {
		fmt.printfln("Unsupported operation '%v' on type '%v'", op, a.kind)
		return types.Data{}, false
	}
	return res, true
}

assert_msg :: proc(cond: bool, msg: string, vm: ^VM, arena: mem.Allocator) {
	if !cond {
		fmt.println("ASSERTION FAILED:")
		fmt.println(msg)
		fmt.printfln("pc:    %d", vm.pc)
		fmt.printfln("sp:    %d", vm.sp)
		fmt.printfln("top:   %v", vm.sp > 0 ? vm.stack[vm.sp-1] : types.data("empty", arena))
		for i in 0..<vm.sp {
			fmt.printfln("  [%d]: %v", i, vm.stack[i])
		}
		fmt.println("memory:")
		for name, index in vm.symbols {
			val := vm.memory[index]
			fmt.printfln("  %q → [%d] = %v", name, index, val)
		}
		os.exit(1)
	}
}

