{
    /* This allows left-associative operators */
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

SourceFile
    = _ a:(v:Statement Comment? EOL { return v })* b:Statement Comment? EOL?
        { return a.concat(b) }

Statement
    = ControlStatement 
    / label:Label? statement:(InstructionStatement / DirectiveStatement / MacroCallStatement)?
        { return { type: "Statement", label, statement }}

// Control Statements
ControlStatement
    = "$" name:Identifier args:(Number / String / Identifier)+
        { return { type: "ControlStatment", name, args } }

// Directives
DirectiveStatement
    // Debugging
    = "CALLS"i WB caller:String callees:("," _ callee:String stack:("," _ v:Expression { return v})? { return { callee, stack } } )+
        { return { type:"CallTraceDirective", caller, callees } }
    / "SYMB"i WB operands:OperandList
        { return { type:"DebugSymbolDirective",  operands } }

    // Assembly Control
    / "ALIGN"i WB value:Expression
        { return { type: "AlignDirective", value } }
    / "COMMENT"i WB delimiter:.  text:$(c:. !{ return c == delimiter })* c:. &{ return c == delimiter } _
        { return { type: "CommentDirective", text } }
    / "DEFINE"i WB name:Identifier value:String
        { return { type: "DefineDirective", name, value } }
    / "DEFSECT"i WB name:String "," _ type:Identifier attributes:("," _ v:SectionAttribute { return v })* location:("AT"i WB v:Expression { return v})?
        { return { type: "DefineSectionDirective", name, type, attributes, location } }
    / "END"i WB
        { return { type: "EndDirective" } }
    / "FAIL"i WB msgs:ExpressionList?
        { return { type: "FailDirective", msgs } }
    / "INCLUDE"i WB file:String
        { return { type: "IncludeDirective", file } } 
    / "INCLUDE"i WB "<" file:$(!">" .)* ">" _
        { return { type: "GlobalIncludeDirective", file } } 
    / "MSG"i WB msgs:ExpressionList?
        { return { type: "MessageDirective", msgs } }
    / "RADIX"i WB value:Expression
        { return { type: "RadixDirective", value } }
    / "SECT"i WB name:String reset:("," _ "RESET"i WB)?
        { return { type: "SectionDirective", name, reset:Boolean(reset) } }
    / "UNDEF"i WB IdentifierList
        { return { type: "UndefineDirective", names } }
    / "WARN"i WB msgs:ExpressionList?
        { return { type: "WarnDirective", msgs } }

    // Symbol Definition
    / name:Identifier "EQU"i WB value:Expression
        { return { type: "EquDirective", name, value } }
    / "EXTERN"i WB attributes:("(" _ v:IdentifierList ")" _ { return v })? names:IdentifierList
        { return { type: "ExternDirective", attributes, names } }
    / "GLOBAL"i WB names:IdentifierList
        { return { type: "GlobalDirective", names } }
    / "LOCAL"i WB names:IdentifierList
        { return { type: "LocalDirective", names } }
    / "NAME"i WB name:String
        { return { type: "NameDirective", name } }
    / name:Identifier "SET"i WB Expression
        { return { type: "SetDirective", name, value } }

    // Data Definition/Storage Allocation
    / "ASCII"i WB values:ExpressionList
        { return { type: "AsciiDirective", values } }
    / "ASCIZ"i WB values:ExpressionList
        { return { type: "TerminatedAsciiDirective", values } }
    / "DB"i WB values:ExpressionList
        { return { type: "DataConstantByteDirective", values } }
    / "DS"i WB values:ExpressionList
        { return { type: "DataStorageDirective", values } }
    / "DW"i WB values:ExpressionList
        { return { type: "DataConstantWordDirective", values } }

    // Macro and Conditional Assembly
    / MacroDirective
    / IfDirective
    / "EXITM"i WB
        { return { type: "ExitMacroDirective" } }
    / "PMACRO"i WB names:IdentifierList
        { return { type: "PurgeMacroDirective", names } }

SectionAttribute
    = "FIT"i WB size:Number
        { return { type: "Fit", size } }
    / "SHORT"i WB
        { return { type: "Short" } }
    / "CLEAR"i WB
        { return { type: "Clear" } }
    / "NOCLEAR"i WB
        { return { type: "NoClear" } }
    / "INIT"i WB
        { return { type: "Init" } }
    / "OVERLAY"i WB
        { return { type: "Overlay" } }
    / "ROMDATA"i WB
        { return { type: "RomData" } }
    / "JOIN"i WB
        { return { type: "Join" } }

// Macro Directives
MacroDirective
    = kind:MacroKind Comment? EOL body:$MacroBody* MacroEnd
        { return { type:"Macro", kind, body } }

MacroKind
    = name:Identifier "MACRO"i WB args:IdentifierList
        { return { type: "MacroDefinition", name, args } }
    / "DUP"i WB count:Expression
        { return { type: "Duplicate", count } }
    / "DUPA"i WB name:Identifier "," _ count:ExpressionList
        { return { type: "DuplicateArgument", name, count } }
    / "DUPC"i WB name:Identifier "," _ string:Expression
        { return { type: "DuplicateCharacters", name, count, string } }
    / "DUPF"i WB name:Identifier start:("," _ v:Expression {return v})? "," _ end:Expression increment:("," _ v:Expression {return v})?
        { return { type: "DuplicateLoop", name, start, end, increment } }

MacroBody
    = !MacroEnd v:$(LineContinuation / !EOL .)* EOL

MacroEnd
    = "ENDM"i WB

// Conditional assembly
IfDirective
    = "IF"i WB condition:Expression Comment? EOL body:ElseIfStatement* elseBody:ElseDirective EndIfDirective
        { return { type: "IfDirective", condition, body, elseBody } }

ElseDirective
    = "ELSE"i WB Comment? EOL body:ElseIfStatement { return body }

EndIfDirective
    = "ENDIF"i WB

ElseIfStatement
    = !(ElseDirective / EndIfDirective) s:Statement Comment? EOL { return s }

// Instruction Statements
InstructionStatement
    // Mnemonic is appened at runtime using the table
    = name:Mnemonic operands:OperandList?
        { return { type: "InstructionStatement", name, operands } }

OperandList
    = a:(v:Operand "," _ { return v })* b:Operand
        { return a.concat(b) }

Operand
    = Expression
    / "#" _ value:Expression
        { return { type:"ImmediateAccess", value } }
    / "[" _ address:Expression "]" _
        { return { type:"MemoryAccess", address } }
    / "[" _ "BR"i _ ":" _ address:Expression "]" _
        { return { type:"TinyMemoryAccess", address } }

// Macro Call
MacroCallStatement
    = name:Identifier args:MacroCallArgList?
        { return { type: "MacroCall", name, args } }

MacroCallArgList
    = a:(v:MacroCallArg "," _ { return v })* b:MacroCallArg
        { a.concat(b) }

MacroCallArg
    = n:$(![ ,\n\r\t] .)* _
        { return n }
    / SingleQuoteString

// Expression
ExpressionList
    = a:(v:Expression "," _ { return v })* b:Expression
        { return a.concat(b) }

Expression
    = first:LogicalAndExpresion rest:("||" _ LogicalAndExpresion)*
        { return assoc(first, rest) }

LogicalAndExpresion
    = first:BitwiseOrExpresion rest:("&&" _ BitwiseOrExpresion)*
        { return assoc(first, rest) }

BitwiseOrExpresion
    = first:BitwiseXorExpresion rest:("|" _ BitwiseXorExpresion)*
        { return assoc(first, rest) }

BitwiseXorExpresion
    = first:BitwiseAndExpresion rest:("^" _ BitwiseAndExpresion)*
        { return assoc(first, rest) }

BitwiseAndExpresion
    = first:EqualityExpression rest:("&" _ EqualityExpression)*
        { return assoc(first, rest) }

EqualityExpression
    = first:CompareExpression rest:(("==" / "!=") _ CompareExpression)*
        { return assoc(first, rest) }

CompareExpression
    = first:ShiftExpression rest:((">=" / "<=" / ">" / "<") _ ShiftExpression)*
        { return assoc(first, rest) }

ShiftExpression
    = first:AdditionExpression rest:(("<<" / ">>") _ AdditionExpression)*
        { return assoc(first, rest) }

AdditionExpression
    = first:MultiplicationExpression rest:(("+" / "-") _ MultiplicationExpression)*
        { return assoc(first, rest) }

MultiplicationExpression
    = first:UnaryExpression rest:(("*" / "/" / "%") _ UnaryExpression)*
        { return assoc(first, rest) }

UnaryExpression
    = "+" _ value:TopExpression
        { return value }
    / "-" _ value:TopExpression
        { return { type: "UnaryExpression", operation: "Negate", value } }
    / "~" _ value:TopExpression
        { return { type: "UnaryExpression", operation: "Complement", value } }
    / "!" _ value:TopExpression
        { return { type: "UnaryExpression", operation: "Not", value } }
    / TopExpression

TopExpression
    = "@" name:Identifier "(" _ args:ExpressionList? ")" _
        { return { type: "FunctionExpression", name, args } }
    / "(" _ e:Expression ")" _
        { return e; }
    / "*" _
        { return { type: "LocationCounter" } }
    / value:Identifier
        { return { type: 'Symbol', value } }
    / value:String
        { return { type: 'String', value } }
    / value:Number
        { return { type: 'Number', value } }

// Atomic values
Label
    = v:Identifier ":" _
        { return v }

IdentifierList
    = a:(v:Identifier "," _ { return v })* b:Identifier
        { return a.concat(b) }

Identifier
    = v:$([_a-z]i ([_a-z0-9]i)*) _
        { return v }
String
    = DoubleQuoteString
    / SingleQuoteString

DoubleQuoteString
    = '"' v:$(!'"' .)* '"' _
        { return v }

SingleQuoteString
    = "'" v:$(!"'" .)* "'" _
        { return v }

Number
    = value:$([0-9] ([0-9a-f]i)*) "h"i _
        { return parseInt(value, 16) }
    / value:$[0-9]+ "d" _
        { return parseInt(value, 10) }
    / value:$[0-8]+ "o"i _
        { return parseInt(value, 8) }
    / value:$[0-1]+ "b"i _
        { return parseInt(value, 2) }
    / value:$([0-9] [0-9a-z]i*) _
        { return { type: "RadixNumber", value } }

// Whitespace based tokens
Comment
    = ";" (LineContinuation / !EOL .)*

LineContinuation
    = "\\" EOL

EOL
    = ("\n" "\r"? / "\r" "\n"?) _

_
    = (LineContinuation / [ \t])*

WB
    = ![_a-z0-9]i _
