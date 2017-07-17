shared interface Node {
    shared formal String tokenLiteral;
}

shared interface Statement satisfies Node {}

shared interface Expression satisfies Node {}

shared class Program(statements) satisfies Node {
    shared Statement[] statements;
    
    tokenLiteral => statements.first?.tokenLiteral else "";
}

shared class Identifier(token, val) satisfies Expression {
    shared Token token;
    
    shared String val;
    
    tokenLiteral = token.literal;
}

shared class LetStatement(token, name, val) satisfies Statement {
    Token token;
    
    shared Identifier name;
    
    shared Expression? val;
    
    tokenLiteral = token.literal;
}
