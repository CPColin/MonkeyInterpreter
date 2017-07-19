import ceylon.test {
    assertEquals,
    test
}

import monkey {
    Lexer,
    MonkeyBoolean,
    MonkeyInteger,
    MonkeyObject,
    Parser,
    eval
}

MonkeyObject? testEval(String input) {
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    return eval(program);
}

void validateBooleanObject(MonkeyObject? val, Boolean expectedValue) {
    value booleanValue = assertType<MonkeyBoolean>(val);
    
    assertEquals(booleanValue.val, expectedValue);
}

void validateIntegerObject(MonkeyObject? val, Integer expectedValue) {
    value integerValue = assertType<MonkeyInteger>(val);
    
    assertEquals(integerValue.val, expectedValue);
}

test
shared void testEvalBooleanExpression() {
    value testParameters = [
    [ "true", true ],
    [ "false", false ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        validateBooleanObject(val, expectedValue);
    }
}

test
shared void testEvalIntegerExpression() {
    value testParameters = [
        [ "5", 5 ],
        [ "10", 10 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        validateIntegerObject(val, expectedValue);
    }
}
