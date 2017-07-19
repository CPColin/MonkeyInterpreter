shared interface Node {
    shared formal String tokenLiteral;
    
    shared actual formal String string;
}

shared interface Statement satisfies Node {}

shared interface Expression satisfies Node {}

shared class Program(statements) satisfies Node {
    shared Statement[] statements;
    
    tokenLiteral = statements.first?.tokenLiteral else "";
    
    string = StringBuilder().appendAll(
            statements
                .map(Statement.string)
                .interpose("\n"))
            .string;
}

shared class BlockStatement(token, statements) satisfies Statement {
    Token token;
    
    shared Statement[] statements;
    
    tokenLiteral = token.literal;
    
    string = StringBuilder().appendAll(
            statements
                .map(Statement.string)
                .interpose("\n"))
            .string;
}

shared class BooleanLiteral(token, val) satisfies Expression {
    Token token;
    
    shared Boolean val;
    
    tokenLiteral = token.literal;
    
    string = tokenLiteral;
}

shared class CallExpression(token, func, arguments) satisfies Expression {
    Token token;
    
    shared Expression? func;
    
    shared Expression[]? arguments;
    
    tokenLiteral = token.literal;
    
    string = "``func else ""``(``if (exists arguments) then StringBuilder().appendAll(arguments.map(Expression.string).interpose(", ")).string else ""``)";
}

shared class ExpressionStatement(token, expression) satisfies Statement {
    Token token;
    
    shared Expression? expression;
    
    tokenLiteral = token.literal;
    
    string = "``expression else ""``";
}

shared class FunctionLiteral(token, parameters, body) satisfies Expression {
    Token token;
    
    shared Identifier[] parameters;
    
    shared BlockStatement body;
    
    tokenLiteral = token.literal;
    
    string = "``tokenLiteral`` (``StringBuilder().appendAll(parameters.map(Identifier.val).interpose(", ")).string``) ``body``";
}

shared class Identifier(token, val) satisfies Expression {
    Token token;
    
    shared String val;
    
    tokenLiteral = token.literal;
    
    string = val;
}

shared class IfExpression(token, condition, consequence, alternative) satisfies Expression {
    Token token;
    
    shared Expression? condition;
    
    shared BlockStatement consequence;
    
    shared BlockStatement? alternative;
    
    tokenLiteral = token.literal;
    
    string = "if ``condition else ""`` ``consequence````if (exists alternative) then " else ``alternative``" else ""``";
}

shared class IntegerLiteral(token, val) satisfies Expression {
    Token token;
    
    shared Integer val;
    
    tokenLiteral = token.literal;
    
    string = tokenLiteral;
}

shared class InfixExpression(token, left, operator, right) satisfies Expression {
    Token token;
    
    shared Expression? left;
    
    shared String operator;
    
    shared Expression? right;
    
    tokenLiteral = token.literal;
    
    string = "(``left else ""`` ``operator`` ``right else ""``)";
}

shared class LetStatement(token, name, val) satisfies Statement {
    Token token;
    
    shared Identifier name;
    
    shared Expression? val;
    
    tokenLiteral = token.literal;
    
    string = "``tokenLiteral`` ``name`` = ``val else ""``;";
}

shared class PrefixExpression(token, operator, right) satisfies Expression {
    Token token;
    
    shared String operator;
    
    shared Expression? right;
    
    tokenLiteral = token.literal;
    
    string = "(``operator````right else ""``)";
}

shared class ReturnStatement(token, returnValue) satisfies Statement {
    Token token;
    
    shared Expression? returnValue;
    
    tokenLiteral = token.literal;
    
    string = "``tokenLiteral`` ``returnValue else ""``;";
}
