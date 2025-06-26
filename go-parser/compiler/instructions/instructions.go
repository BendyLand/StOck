package instructions

import "compiler/ops"

type Data any

type Instruction struct {
    Opcode  ops.OpCode
    Operand Data 
}

type LabeledInstruction struct {
    Label       string 
    Instruction Instruction
}

