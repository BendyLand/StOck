package main

import "core:fmt"

import "tests"
import "types"
import "instructions"
import "vm"

main :: proc() {
	// ast := instructions.get_ast_from_go()
	// state := vm.VM {
	// 	program = ast,
	//     symbols = make(map[string]int),
	//     next_slot = 0,
	// }
	// instructions.show_instructions(ast)
	// vm.run_vm(&state)
	tests.run_tests()
	types.free_allocated_strings()
}
// import "core:mem"
// import "core:strings"

// main :: proc() {
//     // Step 1: Allocate raw memory
//     backing_memory, err := mem.alloc_bytes(1 * mem.Megabyte);
//     if err != .None {
//         panic("Failed to allocate arena backing memory");
//     }
//     defer mem.free_bytes(backing_memory); // Only after program is done using it

//     // Step 2: Declare the arena and initialize it
//     arena: mem.Arena;
//     mem.arena_init(&arena, backing_memory);

//     // Step 3: Create the allocator
//     allocator := mem.arena_allocator(&arena);

//     // Step 4: Use allocator safely
//     my_string := strings.clone("hello", allocator);
//     fmt.println(my_string);
// }


