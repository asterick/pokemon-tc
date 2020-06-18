{
    const operators = {
        "||": "LogicalOr",
        "&&": "LogicalAnd",
        "^": "BitwiseXor",
        "|": "BitwiseOr",
        "&": "BitwiseAnd",
        "!=": "NotEqual",
        "==": "Equal",
        ">": "Greater",
        "<": "Less",
        ">=": "GreaterEqual",
        "<=": "LessEqual",
        "<<": "ShiftLeft",
        ">>": "ShiftRight",
        "*": "Multiply",
        "/": "Divide",
        "%": "Modulo",
        "+": "Add",
        "-": "Subtract"
    }

    function assoc(first, rest) {
        return rest.reduce((left, next) => {
            const [ op, _, right ] = next;
            return { type: "BinaryOperation", operation: operators[op], left, right }
        }, first);
    }
}

SourceLine
    = WS body:Statement comment:Comment? remainder:(EOL v:$(.*) { return v })?
        { return { body, comment, remainder } }

Statement
    = ControlStatement 
    / label:Label? statement:(InstructionStatement / DirectiveStatement / MacroCallStatement)?
        { return { type: "Statement", label, statement }}

ControlStatement
    = "$" name:Identifier args:(Number / String / Identifier)+
        { return { type: "ControlStatment", name, args } }

DirectiveStatement
    = name:Identifier "MACRO"i WB IdentifierList

    / name:Identifier "EQU"i WB Expression
    / name:Identifier "SET"i WB Expression

    / "DEFSECT"i WB String "," WS Identifier ( "," WS SectionAttribute)* ("AT"i WB Expression)?

    / "EXTERN"i WB ("(" WS IdentifierList ")" WS)? IdentifierList
    / "COMMENT"i WB delimiter:. (c:. !{ c == delimiter})*
    / "DEFINE"i WB Identifier Expression
    / "UNDEF"i WB IdentifierList

    / "DUP"i WB Expression
    / "DUPA"i WB Identifier "," WS ExpressionList
    / "DUPC"i WB Identifier "," WS Expression
    / "DUPF"i WB Identifier ("," WS Expression)? "," WS Expression ("," WS Expression)?

    / "INCLUDE"i WB String

    / "ALIGN"i WB ExpressionList
    / "ASCII"i WB ExpressionList
    / "ASCIZ"i WB ExpressionList
    / "CALLS"i WB ExpressionList
    / "DB"i WB ExpressionList
    / "DS"i WB ExpressionList
    / "DW"i WB ExpressionList
    / "END"i WB
    / "ENDIF"i WB
    / "ENDM"i WB
    / "EXITM"i WB
    / "FAIL"i WB ExpressionList?
    / "GLOBAL"i WB ExpressionList?
    / "IF"i WB ExpressionList?
    / "LOCAL"i WB ExpressionList?
    / "MSG"i WB ExpressionList?
    / "NAME"i WB ExpressionList?
    / "PMACRO"i WB ExpressionList?
    / "RADIX"i WB ExpressionList?
    / "SECT"i WB ExpressionList?
    / "SYMB"i WB ExpressionList?
    / "WARN"i WB ExpressionList?

SectionAttribute
    = "FIT"i WB Number
    / "SHORT"i WB
    / "CLEAR"i WB
    / "NOCLEAR"i WB
    / "INIT"i WB
    / "OVERLAY"i WB
    / "ROMDATA"i WB
    / "JOIN"i WB

// Instruction Statements
InstructionStatement
    = name:Mnemonic operands:OperandList?
        { return { type: "InstructionStatement", name, operands } }

Operand
    = Expression
    / "[" WS address:Expression "]" WS
        { return { type:"MemoryAccess", address } }
    / "[" WS "BR"i WS ":" WS address:Expression "]" WS
        { return { type:"TinyMemoryAccess", address } }

// Lists
OperandList
    = a:(v:Operand "," WS { return v })* b:Operand
        { return a.concat(b) }

IdentifierList
    = a:(v:Identifier "," WS { return v })* b:Identifier
        { return a.concat(b) }

MacroCallArgList
    = a:(v:MacroCallArg "," WS { return v })* b:MacroCallArg
        { a.concat(b) }

ExpressionList
    = a:(v:Expression "," WS { return v })* b:Expression
        { return a.concat(b) }

// Macro Call
MacroCallStatement
    = name:Identifier args:MacroCallArgList?
        { return { type: "MacroCall", name, args } }

MacroCallArg
    = n:$(![ ,\n\r\t] .)* WS
        { return n }
    / SingleQuoteString

// Expression
Expression
    = first:LogicalAndExpresion rest:("||" WS LogicalAndExpresion)*
        { return assoc(first, rest) }

LogicalAndExpresion
    = first:BitwiseOrExpresion rest:("&&" WS BitwiseOrExpresion)*
        { return assoc(first, rest) }

BitwiseOrExpresion
    = first:BitwiseXorExpresion rest:("|" WS BitwiseXorExpresion)*
        { return assoc(first, rest) }

BitwiseXorExpresion
    = first:BitwiseAndExpresion rest:("^" WS BitwiseAndExpresion)*
        { return assoc(first, rest) }

BitwiseAndExpresion
    = first:EqualityExpression rest:("&" WS EqualityExpression)*
        { return assoc(first, rest) }

EqualityExpression
    = first:CompareExpression rest:(("==" / "!=") WS CompareExpression)*
        { return assoc(first, rest) }

CompareExpression
    = first:ShiftExpression rest:((">=" / "<=" / ">" / "<") WS ShiftExpression)*
        { return assoc(first, rest) }

ShiftExpression
    = first:AdditionExpression rest:(("<<" / ">>") WS AdditionExpression)*
        { return assoc(first, rest) }

AdditionExpression
    = first:MultiplicationExpression rest:(("+" / "-") WS MultiplicationExpression)*
        { return assoc(first, rest) }

MultiplicationExpression
    = first:UnaryExpression rest:(("*" / "/" / "%") WS UnaryExpression)*
        { return assoc(first, rest) }

UnaryExpression
    = "+" WS value:TopExpression
        { return value }
    / "-" WS value:TopExpression
        { return { type: "UnaryExpression", operation: "Negate", value } }
    / "~" WS value:TopExpression
        { return { type: "UnaryExpression", operation: "Complement", value } }
    / "!" WS value:TopExpression
        { return { type: "UnaryExpression", operation: "Not", value } }
    / TopExpression

TopExpression
    = "@" name:Identifier "(" WS args:ExpressionList? ")" WS
        { return { type: "FunctionExpression", name, args } }
    / "(" WS e:Expression ")" WS
        { return e; }
    / "#" WS value:Expression
        { return { type: 'Immediate', value } }
    / value:Identifier
        { return { type: 'Symbol', value } }
    / value:String
        { return { type: 'String', value } }
    / value:Number
        { return { type: 'Number', value } }

// Atomic values
Label
    = v:Identifier ":" WS
        { return v }

String
    = DoubleQuoteString
    / SingleQuoteString

DoubleQuoteString
    = '"' v:$(!'"' .)* '"' WS
        { return v }

SingleQuoteString
    = "'" v:$(!"'" .)* "'" WS
        { return v }

Number
    = v:$([0-9] ([0-9a-f]i)*) "h"i WS
        { return parseInt(v, 16) }
    / v:$[0-8]+ "o"i WS
        { return parseInt(v, 8) }
    / v:$[0-1]+ "b"i WS
        { return parseInt(v, 2) }
    / v:$[0-9]+ "d"? WS
        { return parseInt(v, 10) }

Identifier
    = v:$([_a-z]i ([_a-z0-9]i)*) WS
        { return v }

// Whitespace based tokens
Comment
    = ";" (![\n\r] .)*

EOL
    = ("\n" "\r"? / "\r" "\n"?)

WS
    = ([ \t] / "\\" EOL)*

WB
    = ![_a-z0-9]i WS
