package types

import "core:strings"
import "core:fmt"
import "core:mem"

ref :: distinct i64

DataType :: union {
	i64, 
	f64,
	bool,
	rune,
	string,
	ref,
}

Data :: struct {
	kind: typeid,
	value: DataType
}

allocated_strings: [dynamic]string

data :: proc(val: DataType) -> Data {
	result: Data
	switch v in val {
	case i64:
		result.kind = i64
	case f64:
		result.kind = f64
	case bool:
		result.kind = bool
	case rune:
		result.kind = rune
	case string:
		result.kind = string
		append(&allocated_strings, strings.clone(v))
		result.value = allocated_strings[len(allocated_strings)-1]
		return result
	case ref:
		result.kind = ref
	}
	result.value = val
	return result
}

free_allocated_strings :: proc() {
	fmt.println(len(allocated_strings))
	for &str in allocated_strings {
		fmt.printfln("DELETING: %q (ptr = %p)", str, &str);
		delete(str)
	}
	delete_dynamic_array(allocated_strings)
}

