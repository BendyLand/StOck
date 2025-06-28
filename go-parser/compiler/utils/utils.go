package utils

import (
	"fmt"
	"parser/shared/instructions"
)

func PrettyPrint(position int, instr instructions.Instruction) {
	var opstr string
	switch val := instr.Operand.(type) {
	case string:
		opstr = fmt.Sprintf("\"%s\"", val)
	default:
		opstr = fmt.Sprintf("%v", val)
	}
	fmt.Printf("%03d: %-12s %v\n", position, instr.Opcode.String(), opstr)
}
