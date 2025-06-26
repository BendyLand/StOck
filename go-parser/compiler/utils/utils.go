package utils

import (
	"fmt"
	"compiler/instructions"
)

func PrettyPrint(position int, instr instructions.Instruction) {
	fmt.Printf("%03d: %-12s %v\n", position, instr.Opcode.String(), instr.Operand)
}
