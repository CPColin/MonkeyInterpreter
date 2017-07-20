import ceylon.language.meta {
    type
}

import ceylon.test {
    assertEquals,
    test
}

import monkey {
    Lexer,
    MonkeyBoolean,
    MonkeyError,
    MonkeyInteger,
    MonkeyNull,
    MonkeyObject,
    Parser,
    eval,
    monkeyFalse,
    monkeyNull,
    monkeyTrue
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
shared void testErrorHandling() {
    value trueType = type(monkeyTrue);
    value testParameters = [
        [ " 5 + true;", MonkeyError.infixTypesNotSupported(`MonkeyInteger`, "+", trueType) ],
        [ " 5 + true; 5;", MonkeyError.infixTypesNotSupported(`MonkeyInteger`, "+", trueType) ],
        [ " -true;", MonkeyError.prefixTypeNotSupported("-", trueType) ],
        [ " true + false;", MonkeyError.infixOperatorNotSupported("+", `MonkeyBoolean`) ],
        [ " 5; true + false; 5;", MonkeyError.infixOperatorNotSupported("+", `MonkeyBoolean`) ],
        [ " if (10 > 1) { true + false; }", MonkeyError.infixOperatorNotSupported("+", `MonkeyBoolean`) ],
        [ "if (10 > 1) {
             if (10 > 1) {
               return true + false;
             }
             
             return 1;
           }",
            MonkeyError.infixOperatorNotSupported("+", `MonkeyBoolean`) ]
    ];
    
    for ([ input, expectedError ] in testParameters) {
        value result = testEval(input);
        value error = assertType<MonkeyError>(result);
        
        assertEquals(error.string, expectedError.string, "Incorrect error message");
    }
}

test
shared void testEvalBangOperator() {
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

test
shared void testEvalIfElseExpressions() {
    value testParameters = [
        [ "if (true) { 10 }", 10 ],
        [ "if (false) { 10 }", monkeyNull ],
        [ "if (1) { 10 }", 10 ],
        [ "if (1 < 2) { 10 }", 10 ],
        [ "if (1 > 2) { 10 }", monkeyNull ],
        [ "if (1 > 2) { 10 } else { 20 }", 20 ],
        [ "if (1 < 2) { 10 } else { 20 }", 10 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        if (is Integer expectedValue) {
            validateIntegerObject(val, expectedValue);
        }
        else {
            assertEquals(val, expectedValue of MonkeyNull, "Value is not null");
        }
    }
}

test
shared void testEvalReturnStatements() {
    value testParameters = [
        [ "return 10;", 10 ],
        [ "return 10; 9;", 10 ],
        [ "return 2 * 5; 9;", 10 ],
        [ "9; return 2 * 5; 9;", 10 ],
        [ "if (10 > 1) {
             if (10 > 1) {
               return 10;
             }
             
             return 1;
           }", 10]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        validateIntegerObject(val, expectedValue);
    }
}
