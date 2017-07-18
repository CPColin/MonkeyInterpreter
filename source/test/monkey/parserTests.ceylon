import ceylon.test {
    assertEquals,
    assertTrue,
    test
}

import monkey {
    BooleanLiteral,
    Expression,
    ExpressionStatement,
    Identifier,
    InfixExpression,
    IntegerLiteral,
    LetStatement,
    Lexer,
    Parser,
    PrefixExpression,
    ReturnStatement,
    Statement
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

void validateReturnStatement(Statement statement, String expression) {
    assertEquals(statement.tokenLiteral, "return", "Incorrect token literal");
    
    assertTrue(statement is ReturnStatement, "Incorrect statement type");
    
    assert (is ReturnStatement statement);
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
    value input = "
                   let x = 5;
                   let y = 10;
                   let foobar = 838383;
                   ";
    
    value expectedIdentifiers = [
        "x",
        "y",
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
        
        // TODO: can use Statement? for parameter type, since we're asserting a type in the validator
        assert (exists statement, exists expectedIdentifier);
        
        validateLetStatement(statement, expectedIdentifier);
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
        [ "!(true == true)", "(!(true == true))" ]
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
    value input = "
                   return 5;
                   return 10;
                   return 993322;
                   ";
    
    value expectedExpressions = [
        "",
        "",
        ""
    ];
    
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    checkParserErrors(parser);
    
    value statements = program.statements;
    
    assertEquals(statements.size, expectedExpressions.size, "Wrong number of statements");
    
    for (index in 0:statements.size) {
        value statement = statements[index];
        value expectedExpression = expectedExpressions[index];
        
        assert (exists statement, exists expectedExpression);
        
        validateReturnStatement(statement, expectedExpression);
    }
}
