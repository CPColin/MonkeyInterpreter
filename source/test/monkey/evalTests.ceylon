import ceylon.language.meta {
    type
}
import ceylon.test {
    assertEquals,
    test
}

import monkey {
    Environment,
    Lexer,
    MonkeyArray,
    MonkeyBoolean,
    MonkeyError,
    MonkeyFunction,
    MonkeyHash,
    MonkeyInteger,
    MonkeyNull,
    MonkeyObject,
    MonkeyString,
    Parser,
    eval,
    monkeyNull,
    monkeyTrue
}

MonkeyObject? testEval(String input) {
    value lexer = Lexer(input);
    value parser = Parser(lexer);
    value program = parser.parseProgram();
    
    return eval(program, Environment());
}

void validateBooleanObject(MonkeyObject? val, Boolean expectedValue) {
    value booleanValue = assertType<MonkeyBoolean>(val);
    
    assertEquals(booleanValue.val, expectedValue);
}

void validateIntegerObject(MonkeyObject? val, Integer expectedValue) {
    value integerValue = assertType<MonkeyInteger>(val);
    
    assertEquals(integerValue.val, expectedValue);
}

void validateNullObject(MonkeyObject? val) {
    assertType<MonkeyNull>(val);
}

test
shared void testBuiltInFunctions() {
    value testParameters = [
        [ """len("");""", 0 ],
        [ """len("four");""", 4 ],
        [ """len("hello world");""", 11 ],
        [ """len(1);""", MonkeyError.argumentTypeMismatch(0, `MonkeyInteger`, `MonkeyArray|MonkeyString`) ],
        [ """len("one", "two");""", MonkeyError.argumentCountMismatch(2, 1) ],
        [ "len([1, 2, 3]);", 3 ],
        [ "len([]);", 0 ],
        [ "first([1, 2, 3]);", 1 ],
        [ "first([]);", null ],
        [ "first(1);", MonkeyError.argumentTypeMismatch(0, `MonkeyInteger`, `MonkeyArray`) ],
        [ "last([1, 2, 3]);", 3 ],
        [ "last([]);", null ],
        [ "last(1);", MonkeyError.argumentTypeMismatch(0, `MonkeyInteger`, `MonkeyArray`) ],
        [ "rest([1, 2, 3]);", [ 2, 3 ] ],
        [ "rest([1]);", empty ],
        [ "rest([]);", null ],
        [ "push([], 1);", [ 1 ] ],
        [ "push([1, 2], 3);", [ 1, 2, 3 ] ],
        [ "push(1, 1);", MonkeyError.argumentTypeMismatch(0, `MonkeyInteger`, `MonkeyArray`) ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value result = testEval(input);
        
        switch (expectedValue)
        case (is Integer) {
            validateIntegerObject(result, expectedValue);
        }
        case (is Integer[]) {
            value array = assertType<MonkeyArray>(result);
            value elements = array.elements;
            
            assertEquals(elements.size, expectedValue.size, "Incorrect number of elements");
            
            for (index in 0:expectedValue.size) {
                value actualVal = elements[index];
                value expectedVal = expectedValue[index];
                
                assert (is Integer expectedVal);
                
                validateIntegerObject(actualVal, expectedVal);
            }
        }
        case (is MonkeyError) {
            value error = assertType<MonkeyError>(result);
            
            assertEquals(error.string, expectedValue.string, "Incorrect error message");
        }
        case (null) {
            validateNullObject(result);
        }
    }
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
            MonkeyError.infixOperatorNotSupported("+", `MonkeyBoolean`) ],
        [ "foobar;", MonkeyError.identifierNotFound("foobar") ],
        [ """"Hello" - "World"""", MonkeyError.infixOperatorNotSupported("-", `MonkeyString`) ],
        [ "{}[fn(x) { x; }];", MonkeyError.hashKeyTypeNotSupported(`MonkeyFunction`)]
    ];
    
    for ([ input, expectedError ] in testParameters) {
        value result = testEval(input);
        value error = assertType<MonkeyError>(result);
        
        assertEquals(error.string, expectedError.string, "Incorrect error message");
    }
}

test
shared void testEvalArrayIndexExpressions() {
    value testParameters = [
        [ "[1, 2, 3][0]", 1 ],
        [ "[1, 2, 3][1]", 2 ],
        [ "[1, 2, 3][2]", 3 ],
        [ "let i = 0; [1][i];", 1 ],
        [ "[1, 2, 3][1 + 1];", 3 ],
        [ "let myArray = [1, 2, 3]; myArray[2];", 3 ],
        [ "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];", 6 ],
        [ "let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]", 2 ],
        [ "[1, 2, 3][3]", null ],
        [ "[1, 2, 3][-1]", null ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        switch (expectedValue)
        case (is Integer) {
            validateIntegerObject(val, expectedValue);
        }
        case (null) {
            validateNullObject(val);
        }
    }
}

test
shared void testEvalArrayLiterals() {
    value input = "[1, 2 * 3, 4 + 5]";
    value result = assertType<MonkeyArray>(testEval(input));
    value elements = result.elements;
    
    assertEquals(elements.size, 3, "Array has wrong number of elements");
    
    validateIntegerObject(elements[0], 1);
    validateIntegerObject(elements[1], 6);
    validateIntegerObject(elements[2], 9);
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
shared void testEvalEnclosingEnvironments() {
    value input = "let first = 10;
                   let second = 10;
                   let third = 10;
                   
                   let ourFunction = fn(first) {
                     let second = 20;
                     
                     first + second + third;
                   };
                   
                   ourFunction(20) + first + second;";
    value expectedValue = 70;
    
    validateIntegerObject(testEval(input), expectedValue);
}

test
shared void testEvalFunction() {
    value testParameters = [
        [ "fn(x) { x + 2; }", [ "x" ], "(x + 2)" ]
    ];
    
    for ([ input, expectedParameters, expectedBody ] in testParameters) {
        value result = assertType<MonkeyFunction>(testEval(input));
        value parameters = result.parameters;
        
        assertEquals(parameters.size, expectedParameters.size, "Wrong number of parameters");
        
        for (index in 0:expectedParameters.size) {
            value parameter = parameters[index];
            value expectedParameter = expectedParameters[index];
            
            assert (exists parameter, exists expectedParameter);
            
            assertEquals(parameter.val, expectedParameter, "Wrong parameter name");
        }
        
        assertEquals(result.body.string, expectedBody, "Wrong function body");
    }
}

test
shared void testEvalFunctionApplication() {
    value testParameters = [
        [ "let identity = fn(x) { x; }; identity(5);", 5 ],
        [ "let identity = fn(x) { return x; }; identity(5);", 5 ],
        [ "let double = fn(x) { x * 2; }; double(5);", 10 ],
        [ "let add = fn(x, y) { x + y; }; add(5, 5);", 10 ],
        [ "let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20 ],
        [ "fn(x) { x; }(5)", 5 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        validateIntegerObject(testEval(input), expectedValue);
    }
}

test
shared void testEvalHashIndexExpressions() {
    value testParameters = [
        [ """{"foo": 5}["foo"]""", 5 ],
        [ """{"foo": 5}["bar"]""", null ],
        [ """let key = "foo"; {"foo": 5}[key]""", 5 ],
        [ """{}["foo"]""", null ],
        [ """{5: 5}[5]""", 5 ],
        [ """{true: 5}[true]""", 5 ],
        [ """{false: 5}[false]""", 5 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        switch (expectedValue)
        case (is Integer) {
            validateIntegerObject(val, expectedValue);
        }
        case (null) {
            validateNullObject(val);
        }
    }
}

test
shared void testEvalHashLiterals() {
    value input = """let two = "two";
                     {
                       "one": 10 - 9,
                       two: 1 + 1,
                       "thr" + "ee": 6 / 2,
                       4: 4,
                       true: 5,
                       false: 6
                     }""";
    value expectedEntries = [
        "one"->1,
        "two"->2,
        "three"->3,
        4->4,
        true->5,
        false->6
    ];
    value result = assertType<MonkeyHash>(testEval(input));
    value map = result.map;
    
    assertEquals(map.size, expectedEntries.size, "Wrong number of entries");
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
shared void testEvalLetStatements() {
    value testParameters = [
        [ "let a = 5; a;", 5 ],
        [ "let a = 5 * 5; a;", 25 ],
        [ "let a = 5; let b = a; b;", 5 ],
        [ "let a = 5; let b = a; let c = a + b + 5; c;", 15 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        validateIntegerObject(testEval(input), expectedValue);
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
           }", 10],
        [ "let f = fn(x) {
             return x;
             x + 10;
           };
           f(10);", 10 ],
        [ "let f = fn(x) {
             let result = x + 10;
             return result;
             return 10;
           };
           f(10);", 20 ]
    ];
    
    for ([ input, expectedValue ] in testParameters) {
        value val = testEval(input);
        
        validateIntegerObject(val, expectedValue);
    }
}

test
shared void testEvalStringConcatenation() {
    value input = """"Hello" + " " + "world!"""";
    value result = assertType<MonkeyString>(testEval(input));
    
    assertEquals(result.val, "Hello world!", "String concatenation failed");
}

test
shared void testEvalStringLiteral() {
    value input = "\"Hello world!\"";
    value result = assertType<MonkeyString>(testEval(input));
    
    assertEquals(result.val, "Hello world!", "String literal changed somehow");
}
