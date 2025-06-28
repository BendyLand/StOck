package ops

type OpCode int

const (
    Push OpCode = iota
    Pop
    Dup
    Swap
    Over
    Rot
    Jump
    JumpIf
    JumpIfNot
    Call
    Return
    Store
    Load
    Input
    Assert
    Noop
    Add
    Sub
    Mult
    Div
    Mod
    PopPrint
    Print
    Halt
    Neg
    Eq
    Neq
    Lt
    Le
    Gt
    Ge
    Not
    And
    Or
    MakeArray
    MakeMap
    GetField
    SetField
)

func (o OpCode) String() string {
    var result string
    switch o {
    case Push: result = "Push"
    case Pop: result = "Pop"
    case Dup: result = "Dup"
    case Swap: result = "Swap"
    case Over: result = "Over"
    case Rot: result = "Rot"
    case Jump: result = "Jump"
    case JumpIf: result = "JumpIf"
    case JumpIfNot: result = "JumpIfNot"
    case Call: result = "Call"
    case Return: result = "Return"
    case Store: result = "Store"
    case Load: result = "Load"
    case Input: result = "Input"
    case Assert: result = "Assert"
    case Noop: result = "Noop"
    case Add: result = "Add"
    case Sub: result = "Sub"
    case Mult: result = "Mult"
    case Div: result = "Div"
    case Mod: result = "Mod"
    case PopPrint: result = "PopPrint"
    case Print: result = "Print"
    case Halt: result = "Halt"
    case Neg: result = "Neg"
    case Eq: result = "Eq"
    case Neq: result = "Neq"
    case Lt: result = "Lt"
    case Le: result = "Le"
    case Gt: result = "Gt"
    case Ge: result = "Ge"
    case Not: result = "Not"
    case And: result = "And"
    case Or: result = "Or"
    case MakeArray: result = "MakeArray"
    case MakeMap: result = "MakeMap"
    case GetField: result = "GetField"
    case SetField: result = "SetField"
    }
    return result
}

