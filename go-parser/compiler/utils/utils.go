package utils

import (
	"fmt"
	i "parser/shared/instructions"
)

func PrettyPrint(position int, instr i.LabeledInstruction) {
	switch instr.(type) {
	case string:
		fmt.Printf("%03d: %-12s\n", position, instr)
	case i.Instruction:
		opcode := instr.(i.Instruction).Opcode.String()
		operand := instr.(i.Instruction).Operand
		fmt.Printf("%03d: %-12s %v\n", position, opcode, operand)
	}
}

