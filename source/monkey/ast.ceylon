shared interface Node {
    shared formal String tokenLiteral;
    
    shared actual formal String string;
}

shared interface Statement satisfies Node {}

shared interface Expression satisfies Node {}

shared class Program(statements) satisfies Node {
    shared Statement[] statements;
    
    tokenLiteral => statements.first?.tokenLiteral else "";
    
    string => StringBuilder().appendAll(
            statements
                .map(Statement.string)
                .interpose("\n"))
            .string;
}

shared class Identifier(token, val) satisfies Expression {
    Token token;
    
    shared String val;
    
    tokenLiteral = token.literal;
    
    string = val;
}

shared class ExpressionStatement(token, expression) satisfies Statement {
    Token token;
    
    shared Expression? expression;
    
    tokenLiteral = token.literal;
    
    string = "``expression?.string else ""``";
}

shared class LetStatement(token, name, val) satisfies Statement {
    Token token;
    
    shared Identifier name;
    
    shared Expression? val;
    
    tokenLiteral = token.literal;
    
    string = "``tokenLiteral`` ``name.string`` = ``val?.string else ""``;";
}

shared class ReturnStatement(token, returnValue) satisfies Statement {
    Token token;
    
    shared Expression? returnValue;
    
    tokenLiteral = token.literal;
    
    string = "``tokenLiteral`` ``returnValue?.string else ""``;";
}
