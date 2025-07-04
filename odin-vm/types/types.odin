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

data :: proc(val: DataType, arena: Maybe(mem.Allocator)) -> Data {
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
		result.value = strings.clone(v, arena.?)
		return result
	case ref:
		result.kind = ref
	}
	result.value = val
	return result
}

