import ceylon.test {
    assertEquals,
    assertTrue,
    test
}

import monkey {
    ExpressionStatement,
    Identifier,
    LetStatement,
    Lexer,
    Parser,
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

void validateLetStatement(Statement statement, String name) {
    assertEquals(statement.tokenLiteral, "let", "Incorrect token literal");
    
    assertTrue(statement is LetStatement, "Incorrect statement type");
    
    assert (is LetStatement statement);
    
    assertEquals(statement.name.val, name, "Incorrect identifier name");
    
    assertEquals(statement.name.tokenLiteral, name, "Incorrect identifier literal");
}

void validateReturnStatement(Statement statement, String expression) {
    assertEquals(statement.tokenLiteral, "return", "Incorrect token literal");
    
    assertTrue(statement is ReturnStatement, "Incorrect statement type");
    
    assert (is ReturnStatement statement);
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
        
        value expression = statement.expression;
        
        assertTrue(expression is Identifier, "Incorrect expression type");
        
        assert (is Identifier expression);
        
        assertEquals(expression.val, expectedIdentifier, "Wrong identifier value");
        
        assertEquals(expression.tokenLiteral, expectedIdentifier, "Wrong token literal");
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
