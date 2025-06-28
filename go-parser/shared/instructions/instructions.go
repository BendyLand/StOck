package instructions

import "parser/shared/ops"

type Data any

type Instruction struct {
    Opcode  ops.OpCode
    Operand Data 
}

type LabeledInstruction any

