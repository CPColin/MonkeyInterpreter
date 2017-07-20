import ceylon.language.meta {
    type,
    typeLiteral
}

import ceylon.test {
    assertEquals,
    assertFalse,
    assertTrue,
    test
}

import monkey {
    BooleanLiteral,
    CallExpression,
    Expression,
    ExpressionStatement,
    FunctionLiteral,
    Identifier,
    IfExpression,
    InfixExpression,
    IntegerLiteral,
    LetStatement,
    Lexer,
    Parser,
    PrefixExpression,
    ReturnStatement,
    Statement,
    StringLiteral
}

// TODO: use all over, watch for double-checking
Type assertType<Type>(Anything val) given Type satisfies Object {
    assertTrue(val is Type, "Value is wrong type: expected ``typeLiteral<Type>()`` but was ``type(val)``");
    
    assert (is Type val);
    
    return val;
}

void checkParserErrors(Parser parser) {
    value errors = parser.errors;
    
    if (errors.size > 0) {
        process.writeErrorLine("Parser has ``errors.size`` error(s):");
        errors.each(process.writeErrorLine);
    }
    
    assertEquals(errors.size, 0, "Parser has errors");
}

void validateBooleanLiteral(Expression? expression, Boolean val) {
    assertTrue(expression is BooleanLiteral, "Wrong expression type");
    
    assert (is BooleanLiteral expression);
    
    assertEquals(expression.val, val, "Wrong boolean value");
    
    assertEquals(expression.tokenLiteral, val.string, "Wrong token literal");
}

void validateIdentifier(Expression? expression, String val) {
    assertTrue(expression is Identifier, "Wrong expression type");
    
    assert (is Identifier expression);
    
    assertEquals(expression.val, val, "Wrong string value");
    
    assertEquals(expression.tokenLiteral, val, "Wrong token literal");
}

void validateIntegerLiteral(Expression? expression, Integer val) {
    assertTrue(expression is IntegerLiteral, "Wrong expression type");
    
    assert (is IntegerLiteral expression);
    
    assertEquals(expression.val, val, "Wrong integer value");
    
    assertEquals(expression.tokenLiteral, val.string, "Wrong token literal");
}

void validateLetStatement(Statement statement, String name) {
    assertEquals(statement.tokenLiteral, "let", "Incorrect token literal");
    
    assertTrue(statement is LetStatement, "Incorrect statement type");
    
    assert (is LetStatement statement);
    
    assertEquals(statement.name.val, name, "Incorrect identifier name");
    
    assertEquals(statement.name.tokenLiteral, name, "Incorrect identifier literal");
}

alias Literal => Boolean|Integer|String;

void validateLiteralExpression(Expression? expression, Literal val) {
    switch (val)
    case (is Boolean) {
        validateBooleanLiteral(expression, val);
    }
    case (is Integer) {
        validateIntegerLiteral(expression, val);
    }
    case (is String) {
        validateIdentifier(expression, val);
    }
}

void validateInfixExpression(Expression? expression, Literal left, String operator, Literal right) {
    assertTrue(expression is InfixExpression, "Incorrect expression type");
    
    assert (is InfixExpression expression);
    
    validateLiteralExpression(expression.left, left);
    
    assertEquals(expression.operator, operator, "Incorrect operator");
    
    validateLiteralExpression(expression.right, right);
}

void validateReturnStatement(Statement? statement, Literal expectedReturnValue) {
    assertTrue(statement is ReturnStatement, "Incorrect statement type");
    
    assert (is ReturnStatement statement);
    
    assertEquals(statement.tokenLiteral, "return", "Incorrect token literal");
    
    validateLiteralExpression(statement.returnValue, expectedReturnValue);
}

test
shared void testBooleanExpressions() {
    value testParameters = [
        [ "true", true ],
        [ "false", false ]
    ];
    
    for ([ input, expectedLiteral ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statements = program.statements;
        
        assertEquals(statements.size, 1, "Should be only one statement");
        
        value statement = statements[0];
        
        assertTrue(statement is ExpressionStatement, "Incorrect statement type");
        
        assert (is ExpressionStatement statement);
        
        validateBooleanLiteral(statement.expression, expectedLiteral);
    }
}

test
shared void testCallExpressionParsing() {
    value input = "add(1, 2 * 3, 4 + 5);";
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, 1, "Wrong number of statements");
    
    value statement = assertType<ExpressionStatement>(statements[0]);
    value expression = assertType<CallExpression>(statement.expression);
    
    validateIdentifier(expression.func, "add");
    
    value arguments = expression.arguments else empty;
    
    assertEquals(arguments.size, 3, "Wrong number of arguments");
    
    validateLiteralExpression(arguments[0], 1);
    validateInfixExpression(arguments[1], 2, "*", 3);
    validateInfixExpression(arguments[2], 4, "+", 5);
}

test
shared void testCallExpressionParameterParsing() {
    value testParameters = [
    [ "add();", "add", empty ],
    [ "add(1);", "add", [ "1" ] ],
    [ "add(1, 2 * 3, 4 + 5);", "add", [ "1", "(2 * 3)", "(4 + 5)" ] ]
    ];
    
    for ([ input, expectedIdentifier, expectedArguments ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statement = assertType<ExpressionStatement>(program.statements[0]);
        value expression = assertType<CallExpression>(statement.expression);
        
        validateIdentifier(expression.func, expectedIdentifier);
        
        value arguments = expression.arguments else empty;
        
        assertEquals(arguments.size, expectedArguments.size, "Wrong number of arguments");
        
        for (index in 0:arguments.size) {
            value argument = arguments[index];
            value expectedArgument = expectedArguments[index];
            
            assert (exists argument, exists expectedArgument);
            
            assertEquals(argument.string, expectedArgument, "Wrong AST string for argument");
        }
    }
}

test
shared void testFunctionLiteralParsing() {
    value input = "fn (x, y) { x + y; }";
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, 1, "Wrong number of statements");
    
    value statement = assertType<ExpressionStatement>(statements[0]);
    value literal = assertType<FunctionLiteral>(statement.expression);
    value parameters = literal.parameters;
    
    assertEquals(parameters.size, 2, "Wrong number of parameters");
    
    validateLiteralExpression(parameters[0], "x");
    validateLiteralExpression(parameters[1], "y");
    
    value bodyStatements = literal.body.statements;
    
    assertEquals(bodyStatements.size, 1, "Wrong number of body statements");
    
    value bodyStatement = assertType<ExpressionStatement>(bodyStatements[0]);
    
    validateInfixExpression(bodyStatement.expression, "x", "+", "y");
}

test
shared void testFunctionParameterParsing() {
    value testParameters = [
        [ "fn() {};", empty ],
        [ "fn(x) {};", [ "x" ] ],
        [ "fn(x, y, z) {};", [ "x", "y", "z" ] ]
    ];
    
    for ([ input, expectedParameters ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statement = assertType<ExpressionStatement>(program.statements[0]);
        value functionLiteral = assertType<FunctionLiteral>(statement.expression);
        value parameters = functionLiteral.parameters;
        
        assertEquals(parameters.size, expectedParameters.size, "Wrong number of parameters");
        
        for (index in 0:parameters.size) {
            value parameter = parameters[index];
            value expectedParameter = expectedParameters[index];
            
            assert (exists parameter, exists expectedParameter);
            
            validateLiteralExpression(parameter, expectedParameter);
        }
    }
}

test
shared void testIdentifierExpression() {
    value input = "foobar;";
    
    value expectedIdentifiers = [
        "foobar"
    ];
    
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, expectedIdentifiers.size, "Wrong number of statements");
    
    for (index in 0:statements.size) {
        value statement = statements[index];
        value expectedIdentifier = expectedIdentifiers[index];
        
        assert (exists statement, exists expectedIdentifier);
        
        assertTrue(statement is ExpressionStatement, "Incorrect statement type");
        
        assert (is ExpressionStatement statement);
        
        validateLiteralExpression(statement.expression, expectedIdentifier);
    }
}

test
shared void testIfExpression() {
    value input = "if (x < y) { x }";
    
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, 1, "Wrong number of statements");
    
    value statement = assertType<ExpressionStatement>(statements[0]);
    
    value expression = assertType<IfExpression>(statement.expression);
    
    validateInfixExpression(expression.condition, "x", "<", "y");
    
    value consequenceStatements = expression.consequence.statements;
    
    assertEquals(consequenceStatements.size, 1, "Wrong number of consequence statements");
    
    value consequence = assertType<ExpressionStatement>(consequenceStatements[0]);
    
    validateIdentifier(consequence.expression, "x");
    
    assertFalse(expression.alternative exists, "Alternative should not exist");
}

test
shared void testIfElseExpression() {
    value input = "if (x < y) { x } else { y }";
    
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, 1, "Wrong number of statements");
    
    value statement = assertType<ExpressionStatement>(statements[0]);
    
    value expression = assertType<IfExpression>(statement.expression);
    
    validateInfixExpression(expression.condition, "x", "<", "y");
    
    value consequenceStatements = expression.consequence.statements;
    
    assertEquals(consequenceStatements.size, 1, "Wrong number of consequence statements");
    
    value consequence = assertType<ExpressionStatement>(consequenceStatements[0]);
    
    validateIdentifier(consequence.expression, "x");
    
    value alternativeStatements = expression.alternative?.statements else empty;
    
    assertEquals(consequenceStatements.size, 1, "Wrong number of alternative statements");
    
    value alternative = assertType<ExpressionStatement>(alternativeStatements[0]);
    
    validateIdentifier(alternative.expression, "y");
}

test
shared void testIntegerLiteralExpression() {
    value input = "5;";
    
    value expectedLiterals = [
        5
    ];
    
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, expectedLiterals.size, "Wrong number of statements");
    
    for (index in 0:statements.size) {
        value statement = statements[index];
        value expectedLiteral = expectedLiterals[index];
        
        assert (exists statement, exists expectedLiteral);
        
        assertTrue(statement is ExpressionStatement, "Incorrect statement type");
        
        assert (is ExpressionStatement statement);
        
        validateLiteralExpression(statement.expression, expectedLiteral);
    }
}

test
shared void testLetStatements() {
    value testParameters = [
        [ "let x = 5;", "x", 5 ],
        [ "let y = true;", "y", true ],
        [ "let foobar = y;", "foobar", "y" ]
    ];
        
    for ([ input, expectedIdentifier, expectedValue ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statements = program.statements;
        
        assertEquals(statements.size, 1, "Wrong number of statements");
        
        value statement = assertType<LetStatement>(statements[0]);
        
        validateLetStatement(statement, expectedIdentifier);
        
        validateLiteralExpression(statement.val, expectedValue);
    }
}

test
shared void testOperatorPrecedenceParsing() {
    value testParameters = [
        [ "-a * b", "((-a) * b)" ],
        [ "!-a", "(!(-a))" ],
        [ "a + b + c", "((a + b) + c)" ],
        [ "a + b - c", "((a + b) - c)" ],
        [ "a * b * c", "((a * b) * c)" ],
        [ "a * b / c", "((a * b) / c)" ],
        [ "a + b / c", "(a + (b / c))" ],
        [ "a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)" ],
        [ "3 + 4; -5 * 5", "(3 + 4)
                            ((-5) * 5)" ],
        [ "5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))" ],
        [ "5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))" ],
        [ "3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))" ],
        [ "true", "true" ],
        [ "false", "false" ],
        [ "3 > 5 == false", "((3 > 5) == false)" ],
        [ "3 < 5 == true", "((3 < 5) == true)" ],
        [ "1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)" ],
        [ "(5 + 5) * 2", "((5 + 5) * 2)" ],
        [ "2 / (5 + 5)", "(2 / (5 + 5))" ],
        [ "-(5 + 5)", "(-(5 + 5))" ],
        [ "!(true == true)", "(!(true == true))" ],
        [ "a + add(b * c) + d", "((a + add((b * c))) + d)" ],
        [ "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
            "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))" ],
        [ "add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))" ]
    ];
    
    for ([ input, expectedString ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        assertEquals(program.string, expectedString, "Incorrect AST string");
    }
}

test
shared void testParsingInfixExpressions() {
    value testParameters = [
        [ "5 + 5;", 5, "+", 5 ],
        [ "5 - 5;", 5, "-", 5 ],
        [ "5 * 5;", 5, "*", 5 ],
        [ "5 / 5;", 5, "/", 5 ],
        [ "5 > 5;", 5, ">", 5 ],
        [ "5 < 5;", 5, "<", 5 ],
        [ "5 == 5;", 5, "==", 5 ],
        [ "5 != 5;", 5, "!=", 5 ],
        [ "true == true;", true, "==", true ],
        [ "true != false;", true, "!=", false ],
        [ "false == false;", false, "==", false ]
    ];
    
    for ([ input, expectedLeftLiteral, expectedOperator, expectedRightLiteral ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statements = program.statements;
        
        assertEquals(statements.size, 1, "Should be only one statement");
        
        value statement = statements[0];
        
        assertTrue(statement is ExpressionStatement, "Incorrect statement type");
        
        assert (is ExpressionStatement statement);
        
        validateInfixExpression(statement.expression,
            expectedLeftLiteral, expectedOperator, expectedRightLiteral);
    }
}

test
shared void testParsingPrefixExpressions() {
    value testParameters = [
        [ "!5;", "!", 5 ],
        [ "-15;", "-", 15 ],
        [ "!true;", "!", true ],
        [ "!false;", "!", false ]
    ];
    
    for ([ input, expectedOperator, expectedLiteral ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statements = program.statements;
        
        assertEquals(statements.size, 1, "Should be only one statement");
        
        value statement = statements[0];
        
        assertTrue(statement is ExpressionStatement, "Incorrect statement type");
        
        assert (is ExpressionStatement statement);
        
        value expression = statement.expression;
        
        assertTrue(expression is PrefixExpression);
        
        assert (is PrefixExpression expression);
        
        assertEquals(expression.operator, expectedOperator, "Incorrect operator");
        
        validateLiteralExpression(expression.right, expectedLiteral);
    }
}

test
shared void testReturnStatements() {
    value testParameters = [
        [ "return 5;", 5 ],
        [ "return true;", true ],
        [ "return foobar;", "foobar" ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value lexer = Lexer(input);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        
        checkParserErrors(parser);
        
        value statements = program.statements;
        
        assertEquals(statements.size, 1, "Wrong number of statements");
        
        validateReturnStatement(statements[0], expectedValue);
    }
}

test
shared void testStringLiteral() {
    value input = "\"hello world\"";
    value expectedValue = "hello world";
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, 1, "Wrong number of statements");
    
    value statement = assertType<ExpressionStatement>(statements[0]);
    value literal = assertType<StringLiteral>(statement.expression);
    
    assertEquals(literal.val, expectedValue, "Wrong string value");
}
