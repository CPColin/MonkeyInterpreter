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
shared void testBangOperator() {
    value testParameters = [
        [ "!true", false ],
        [ "!false", true ],
        [ "!5", false ],
        [ "!!true", true ],
        [ "!!false", false ],
        [ "!!5", true ]
    ];
    
    for ([ input, expectedValue] in testParameters) {
        value val = testEval(input);
        
        validateBooleanObject(val, expectedValue);
    }
}

test
shared void testEvalBooleanExpression() {
    value testParameters = [
        [ "true", true ],
        [ "false", false ],
        [ "1 < 2", true ],
        [ "1 > 2", false ],
        [ "1 < 1", false ],
        [ "1 > 1", false ],
        [ "1 == 1", true ],
        [ "1 != 1", false ],
        [ "1 == 2", false ],
        [ "1 != 2", true ],
        [ "true == true", true ],
        [ "false == false", true ],
        [ "true == false", false ],
        [ "true != false", true ],
        [ "false != true", true ],
        [ "(1 < 2) == true", true ],
        [ "(1 < 2) == false", false ],
        [ "(1 > 2) == true", false ],
        [ "(1 > 2) == false", true ]
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
        [ "10", 10 ],
        [ "-5", -5 ],
        [ "-10", -10 ],
        [ "5 + 5 + 5 + 5 - 10", 10 ],
        [ "2 * 2 * 2 * 2 * 2", 32 ],
        [ "-50 + 100 + -50", 0 ],
        [ "5 * 2 + 10", 20 ],
        [ "5 + 2 * 10", 25 ],
        [ "20 + 2 * -10", 0 ],
        [ "50 / 2 * 2 + 10", 60 ],
        [ "2 * (5 + 10)", 30 ],
        [ "3 * 3 * 3 + 10", 37 ],
        [ "3 * (3 * 3) + 10", 37 ],
        [ "(5 + 10 * 2 + 15 / 3) * 2 + -10", 50 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        validateIntegerObject(val, expectedValue);
    }
}
