package types

DataType :: union {
	i64,
	f64,
	bool,
	rune,
	string,
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
	}
	return result
}

