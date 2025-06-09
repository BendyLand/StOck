package ops

OpCode :: enum {
    Push, // done
    Pop,
    Dup,
    Swap,
    Over,
    Rot,
    // Jump(offset: int), // these require an int argument
    // JumpIf(offset: int),
    // JumpIfNot(offset: int),
    // Store(slot_id: int),
    // Load(slot_id: int),
    Input,
    Assert,
    Noop,
    Add, // done
    Sub, // done
    Mult, // done
    Div, //  done
    Mod, // done
    PopPrint, 
    Print,
    Halt, // done
    Neg, 
    Eq,
    Neq,
    Lt,
    Le,
    Gt,
    Ge,
    Not,
    And,
    Or,
}

