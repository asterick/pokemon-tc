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

    function assoc(first, rest, location ) {
        return rest.reduce((left, next) => {
            const [ op, _, right ] = next;
            return { type: "BinaryOperation", operation: operators[op], left, right, location }
        }, first);
    }
}

SourceFile
    = _ a:(v:Statement Comment? EOL { return v })* b:Statement Comment? EOL?
        { return a.concat(b) }

Statement
    = ControlStatement 
    / label:Label? statement:(InstructionStatement / DirectiveStatement / MacroCallStatement)?
        { return { type: "Statement", label, statement, location }}

// Control Statements
ControlStatement
    = "$" name:Identifier args:(Number / String / Identifier)+
        { return { type: "ControlStatment", name, args, location } }

// Directives
DirectiveStatement
    // Debugging
    = "CALLS"i WB caller:String callees:("," _ callee:String stack:("," _ v:Expression { return v})? { return { callee, stack } } )+
        { return { type:"CallTraceDirective", caller, callees, location } }
    / "SYMB"i WB operands:OperandList
        { return { type:"DebugSymbolDirective",  operands, location } }

    // Assembly Control
    / "ALIGN"i WB value:Expression
        { return { type: "AlignDirective", value, location } }
    / "COMMENT"i WB delimiter:.  text:$(c:. !{ return c == delimiter })* c:. &{ return c == delimiter } _
        { return { type: "CommentDirective", text, location } }
    / "DEFINE"i WB name:Identifier value:String
        { return { type: "DefineDirective", name, value, location } }
    / "DEFSECT"i WB name:String "," _ type:Identifier attributes:("," _ v:SectionAttribute { return v })* location:("AT"i WB v:Expression { return v})?
        { return { type: "DefineSectionDirective", name, type, attributes, location, location } }
    / "END"i WB
        { return { type: "EndDirective", location } }
    / "FAIL"i WB msgs:ExpressionList?
        { return { type: "FailDirective", msgs, location } }
    / "INCLUDE"i WB file:String
        { return { type: "IncludeDirective", file, location } } 
    / "INCLUDE"i WB "<" file:$(!">" .)* ">" _
        { return { type: "GlobalIncludeDirective", file, location } } 
    / "MSG"i WB msgs:ExpressionList?
        { return { type: "MessageDirective", msgs, location } }
    / "RADIX"i WB value:Expression
        { return { type: "RadixDirective", value, location } }
    / "SECT"i WB name:String reset:("," _ "RESET"i WB)?
        { return { type: "SectionDirective", name, reset:Boolean(reset), location } }
    / "UNDEF"i WB IdentifierList
        { return { type: "UndefineDirective", names, location } }
    / "WARN"i WB msgs:ExpressionList?
        { return { type: "WarnDirective", msgs, location } }

    // Symbol Definition
    / name:Identifier "EQU"i WB value:Expression
        { return { type: "EquDirective", name, value, location } }
    / "EXTERN"i WB attributes:("(" _ v:IdentifierList ")" _ { return v })? names:IdentifierList
        { return { type: "ExternDirective", attributes, names, location } }
    / "GLOBAL"i WB names:IdentifierList
        { return { type: "GlobalDirective", names, location } }
    / "LOCAL"i WB names:IdentifierList
        { return { type: "LocalDirective", names, location } }
    / "NAME"i WB name:String
        { return { type: "NameDirective", name, location } }
    / name:Identifier "SET"i WB Expression
        { return { type: "SetDirective", name, value, location } }

    // Data Definition/Storage Allocation
    / "ASCII"i WB values:ExpressionList
        { return { type: "AsciiDirective", values, location } }
    / "ASCIZ"i WB values:ExpressionList
        { return { type: "TerminatedAsciiDirective", values, location } }
    / "DB"i WB values:ExpressionList
        { return { type: "DataConstantByteDirective", values, location } }
    / "DS"i WB values:ExpressionList
        { return { type: "DataStorageDirective", values, location } }
    / "DW"i WB values:ExpressionList
        { return { type: "DataConstantWordDirective", values, location } }

    // Macro and Conditional Assembly
    / MacroDirective
    / IfDirective
    / "EXITM"i WB
        { return { type: "ExitMacroDirective", location } }
    / "PMACRO"i WB names:IdentifierList
        { return { type: "PurgeMacroDirective", names, location } }

SectionAttribute
    = "FIT"i WB size:Number
        { return { type: "Fit", size, location } }
    / "SHORT"i WB
        { return { type: "Short", location } }
    / "CLEAR"i WB
        { return { type: "Clear", location } }
    / "NOCLEAR"i WB
        { return { type: "NoClear", location } }
    / "INIT"i WB
        { return { type: "Init", location } }
    / "OVERLAY"i WB
        { return { type: "Overlay", location } }
    / "ROMDATA"i WB
        { return { type: "RomData", location } }
    / "JOIN"i WB
        { return { type: "Join", location } }

// Macro Directives
MacroDirective
    = kind:MacroKind Comment? EOL body:$MacroBody* MacroEnd
        { return { type:"Macro", kind, body, location } }

MacroKind
    = name:Identifier "MACRO"i WB args:IdentifierList
        { return { type: "MacroDefinition", name, args, location } }
    / "DUP"i WB count:Expression
        { return { type: "Duplicate", count, location } }
    / "DUPA"i WB name:Identifier "," _ count:ExpressionList
        { return { type: "DuplicateArgument", name, count, location } }
    / "DUPC"i WB name:Identifier "," _ string:Expression
        { return { type: "DuplicateCharacters", name, count, string, location } }
    / "DUPF"i WB name:Identifier start:("," _ v:Expression {return v})? "," _ end:Expression increment:("," _ v:Expression {return v})?
        { return { type: "DuplicateLoop", name, start, end, increment, location } }

MacroBody
    = !MacroEnd v:$(LineContinuation / !EOL .)* EOL

MacroEnd
    = "ENDM"i WB

// Conditional assembly
IfDirective
    = "IF"i WB condition:Expression Comment? EOL body:ElseIfStatement* elseBody:ElseDirective EndIfDirective
        { return { type: "IfDirective", condition, body, elseBody, location } }

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
        { return { type: "InstructionStatement", name, operands, location } }

OperandList
    = a:(v:Operand "," _ { return v })* b:Operand
        { return a.concat(b) }

Operand
    = Expression
    / "#" _ value:Expression
        { return { type:"ImmediateAccess", value, location } }
    / "[" _ address:Expression "]" _
        { return { type:"MemoryAccess", address, location } }
    / "[" _ "BR"i _ ":" _ address:Expression "]" _
        { return { type:"TinyMemoryAccess", address, location } }

// Macro Call
MacroCallStatement
    = name:Identifier args:MacroCallArgList?
        { return { type: "MacroCall", name, args, location } }

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
        { return assoc(first, rest, location ) }

LogicalAndExpresion
    = first:BitwiseOrExpresion rest:("&&" _ BitwiseOrExpresion)*
        { return assoc(first, rest, location ) }

BitwiseOrExpresion
    = first:BitwiseXorExpresion rest:("|" _ BitwiseXorExpresion)*
        { return assoc(first, rest, location ) }

BitwiseXorExpresion
    = first:BitwiseAndExpresion rest:("^" _ BitwiseAndExpresion)*
        { return assoc(first, rest, location ) }

BitwiseAndExpresion
    = first:EqualityExpression rest:("&" _ EqualityExpression)*
        { return assoc(first, rest, location ) }

EqualityExpression
    = first:CompareExpression rest:(("==" / "!=") _ CompareExpression)*
        { return assoc(first, rest, location ) }

CompareExpression
    = first:ShiftExpression rest:((">=" / "<=" / ">" / "<") _ ShiftExpression)*
        { return assoc(first, rest, location ) }

ShiftExpression
    = first:AdditionExpression rest:(("<<" / ">>") _ AdditionExpression)*
        { return assoc(first, rest, location ) }

AdditionExpression
    = first:MultiplicationExpression rest:(("+" / "-") _ MultiplicationExpression)*
        { return assoc(first, rest, location ) }

MultiplicationExpression
    = first:UnaryExpression rest:(("*" / "/" / "%") _ UnaryExpression)*
        { return assoc(first, rest, location ) }

UnaryExpression
    = "+" _ value:TopExpression
        { return value }
    / "-" _ value:TopExpression
        { return { type: "UnaryExpression", operation: "Negate", value, location } }
    / "~" _ value:TopExpression
        { return { type: "UnaryExpression", operation: "Complement", value, location } }
    / "!" _ value:TopExpression
        { return { type: "UnaryExpression", operation: "Not", value, location } }
    / TopExpression

TopExpression
    = "@" name:Identifier "(" _ args:ExpressionList? ")" _
        { return { type: "FunctionExpression", name, args, location } }
    / "(" _ e:Expression ")" _
        { return e; }
    / "*" _
        { return { type: "LocationCounter", location } }
    / value:Identifier
        { return { type: 'Symbol', value, location } }
    / value:String
        { return { type: 'String', value, location } }
    / value:Number
        { return { type: 'Number', value, location } }

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
