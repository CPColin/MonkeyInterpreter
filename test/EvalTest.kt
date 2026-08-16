import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments.arguments
import org.junit.jupiter.params.provider.MethodSource
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.fail

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class EvalTest {
    private fun assertEval(input: String, expected: Any?) {
        val result = context(Environment()) {
            eval(Parser(Lexer(input)).parseProgram())
        }

        assertEvalResult(expected, result)
    }

    private fun assertEvalResult(expected: Any?, result: MonkeyObject) {
        if (result is MonkeyError) {
            fail(result.message)
        }

        when (expected) {
            is Array<*> -> {
                assertIs<MonkeyArray>(result)
                for ((index, element) in expected.withIndex()) {
                    assertEvalResult(element, result.elements[index])
                }
            }
            is Boolean -> {
                assertIs<MonkeyBoolean>(result)
                assertEquals(expected, result.value)
            }
            is Int -> {
                assertIs<MonkeyInteger>(result)
                assertEquals(expected, result.value)
            }
            is String -> {
                assertIs<MonkeyString>(result)
                assertEquals(expected, result.value)
            }
            null -> {
                assertIs<MonkeyNull>(result)
            }
            else -> error("Unsupported type in assertEval: ${expected::class}")
        }
    }

    private fun error() = listOf(
        arguments(
            "5 + true;",
            "type mismatch: INTEGER + BOOLEAN",
        ),
        arguments(
            "5 + true; 5;",
            "type mismatch: INTEGER + BOOLEAN",
        ),
        arguments(
            "-true",
            "unknown operator: -BOOLEAN",
        ),
        arguments(
            "true + false;",
            "unknown operator: BOOLEAN + BOOLEAN",
        ),
        arguments(
            "5; true + false; 5",
            "unknown operator: BOOLEAN + BOOLEAN",
        ),
        arguments(
            "if (10 > 1) { true + false; }",
            "unknown operator: BOOLEAN + BOOLEAN",
        ),
        arguments(
            """
                if (10 > 1) {
                    if (10 > 1) {
                        return true + false;
                    }
        
                    return 1;
                }
                """.trimIndent(),
            "unknown operator: BOOLEAN + BOOLEAN",
        ),
        arguments(
            "foobar",
            "identifier not found: foobar"
        ),
        arguments(
            """"Hello" - "World"""",
            "unknown operator: STRING - STRING"
        ),
        arguments(
            "len(1)",
            "argument to `len` not supported, got INTEGER"
        ),
        arguments(
            """len("one", "two")""",
            "wrong number of arguments. got 2, but wanted 1"
        )
    )

    @ParameterizedTest
    @MethodSource
    fun error(input: String, expected: String) {
        val result = context(Environment()) {
            eval(Parser(Lexer(input)).parseProgram())
        }

        assertIs<MonkeyError>(result)
        assertEquals(expected, result.message)
    }

    private fun eval() = listOf(
        // booleans
        arguments("true", true),
        arguments("false", false),
        arguments("1 < 2", true),
        arguments("1 > 2", false),
        arguments("1 < 1", false),
        arguments("1 > 1", false),
        arguments("1 == 1", true),
        arguments("1 != 1", false),
        arguments("1 == 2", false),
        arguments("1 != 2", true),
        arguments("true == true", true),
        arguments("false == false", true),
        arguments("true == false", false),
        arguments("true != false", true),
        arguments("true != true", false),
        arguments("(1 < 2) == true", true),
        arguments("(1 < 2) == false", false),
        arguments("(1 > 2) == true", false),
        arguments("(1 > 2) == false", true),
        arguments(""""Hello" == "World"""", false),
        arguments(""""Hello" != "World"""", true),
        arguments(""""Hello" == "Hello"""", true),
        arguments(""""Hello" != "Hello"""", false),
        // ints
        arguments("5", 5),
        arguments("10", 10),
        arguments("-5", -5),
        arguments("-10", -10),
        arguments("5 + 5 + 5 + 5 - 10", 10),
        arguments("2 * 2 * 2 * 2 * 2", 32),
        arguments("-50 + 100 + -50", 0),
        arguments("5 * 2 + 10", 20),
        arguments("5 + 2 * 10", 25),
        arguments("20 + 2 * -10", 0),
        arguments("50 / 2 * 2 + 10", 60),
        arguments("2 * (5 + 10)", 30),
        arguments("3 * 3 * 3 + 10", 37),
        arguments("3 * (3 * 3) + 10", 37),
        arguments("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
        // strings
        arguments(
            """
                "Hello World!"
                """.trimIndent(),
            "Hello World!"
        ),
        arguments(""""Hello" + " " + "World"""", "Hello World"),
        // bang operator
        arguments("!true", false),
        arguments("!false", true),
        arguments("!5", false),
        arguments("!!true", true),
        arguments("!!false", false),
        arguments("!!5", true),
        // call expressions
        arguments("let identity = fn(x) { x; }; identity(5);", 5),
        arguments("let identity = fn(x) { return x; }; identity(5);", 5),
        arguments("let double = fn(x) { x * 2; }; double(5);", 10),
        arguments("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
        arguments("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
        arguments("fn(x) { x; }(5)", 5),
        arguments(
            """
                let newAdder = fn(x) {
                  fn(y) { x + y };
                };

                let addTwo = newAdder(2);
                addTwo(2);
                """.trimIndent(),
            4
        ),
        // if-else expressions
        arguments("if (true) { 10 }", 10),
        arguments("if (false) { 10 }", null),
        arguments("if (1) { 10 }", 10),
        arguments("if (1 < 2) { 10 }", 10),
        arguments("if (1 > 2) { 10 }", null),
        arguments("if (1 > 2) { 10 } else { 20 }", 20),
        arguments("if (1 < 2) { 10 } else { 20 }", 10),
        // let statements
        arguments("let a = 5; a;", 5),
        arguments("let a = 5 * 5; a;", 25),
        arguments("let a = 5; let b = a; b;", 5),
        arguments("let a = 5; let b = a; let c = a + b + 5; c;", 15),
        // return statements
        arguments("return 10;", 10),
        arguments("return 10; 9;", 10),
        arguments("return 2 * 5; 9;", 10),
        arguments("9; return 2 * 5; 9;", 10),
        arguments(
            """
                if (10 > 1) {
                  if (10 > 1) {
                    return 10;
                  }

                  return 1;
                }
                """.trimIndent(),
            10
        ),
        // built-in functions
        arguments("""len("")""", 0),
        arguments("""len("four")""", 4),
        arguments("""len("hello world")""", 11),
        arguments("len([1, 2, 3])", 3),
        arguments("first([1, 2, 3])", 1),
        arguments("last([1, 2, 3])", 3),
        arguments("rest([1, 2, 3])", arrayOf(2, 3)),
        arguments("push([1, 2, 3], 4)", arrayOf(1, 2, 3, 4)),
        arguments(
            """
                let map = fn(arr, f) {
                  let iter = fn(arr, accumulated) {
                    if (len(arr) == 0) {
                      accumulated
                    } else {
                      iter(rest(arr), push(accumulated, f(first(arr))));
                    }
                  };

                  iter(arr, []);
                };
                
                map([1, 2, 3, 4], fn(x) { x * 2 });
                """.trimIndent(),
            arrayOf(2, 4, 6, 8)
        ),
        // array literals
        arguments("[1, 2 + 2, 3 * 3]", arrayOf(1, 4, 9)),
        // index expressions
        arguments("[1, 2, 3][0]", 1),
        arguments("[1, 2, 3][1]", 2),
        arguments("[1, 2, 3][2]", 3),
        arguments("let i = 0; [1][i];", 1),
        arguments("[1, 2, 3][1 + 1];", 3),
        arguments("let myArray = [1, 2, 3]; myArray[2];", 3),
        arguments("let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];", 6),
        arguments("let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]", 2),
        arguments("[1, 2, 3][3]", null),
        arguments("[1, 2, 3][-1]", null),
        arguments("puts(123)", null)
    )

    @ParameterizedTest
    @MethodSource
    fun eval(input: String, expected: Any?) {
        assertEval(input, expected)
    }

    private fun functionLiteral() = listOf(
        arguments("fn(x) { x + 2; }", listOf("x"), "(x + 2)")
    )

    @ParameterizedTest
    @MethodSource
    fun functionLiteral(input: String, expectedParameters: List<String>, expectedBody: String) {
        val result = context(Environment()) {
            eval(Parser(Lexer(input)).parseProgram())
        }

        assertIs<MonkeyFunction>(result)
        assertEquals(expectedParameters, result.function.parameters.map(Identifier::value))
        assertEquals(expectedBody, result.function.body.string)
    }
}
