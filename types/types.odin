package types

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

data :: proc(val: DataType) -> Data {
	result: Data
	result.value = val
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
	case ref:
		result.kind = ref
	}
	return result
}

