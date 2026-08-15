import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments.arguments
import org.junit.jupiter.params.provider.MethodSource
import kotlin.test.assertEquals
import kotlin.test.assertIs

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class EvalTest {
    private fun eval(input: String): MonkeyObject =
        context(Environment()) {
            eval(Parser(Lexer(input)).parseProgram())
        }

    private fun bang() = listOf(
        arguments("!true", false),
        arguments("!false", true),
        arguments("!5", false),
        arguments("!!true", true),
        arguments("!!false", false),
        arguments("!!5", true)
    )

    @ParameterizedTest
    @MethodSource
    fun bang(input: String, expected: Boolean) {
        val result = eval(input)

        assertIs<MonkeyBoolean>(result)
        assertEquals(expected, result.value)
    }

    private fun booleanExpression() = listOf(
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
        arguments(""""Hello" != "Hello"""", false)
    )

    @ParameterizedTest
    @MethodSource
    fun booleanExpression(input: String, expected: Boolean) {
        val result = eval(input)

        assertIs<MonkeyBoolean>(result)
        assertEquals(expected, result.value)
    }

    private fun callExpression() = listOf(
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
        )
    )

    @ParameterizedTest
    @MethodSource
    fun callExpression(input: String, expected: Int) {
        val result = eval(input)

        assertIs<MonkeyInteger>(result)
        assertEquals(expected, result.value)
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
        )
    )

    @ParameterizedTest
    @MethodSource
    fun error(input: String, expected: String) {
        val result = eval(input)

        assertIs<MonkeyError>(result)
        assertEquals(expected, result.message)
    }

    private fun functionLiteral() = listOf(
        arguments("fn(x) { x + 2; }", listOf("x"), "(x + 2)")
    )

    @ParameterizedTest
    @MethodSource
    fun functionLiteral(input: String, expectedParameters: List<String>, expectedBody: String) {
        val result = eval(input)

        assertIs<MonkeyFunction>(result)
        assertEquals(expectedParameters, result.function.parameters.map(Identifier::value))
        assertEquals(expectedBody, result.function.body.string)
    }

    private fun ifElseExpression() = listOf(
        arguments("if (true) { 10 }", 10),
        arguments("if (false) { 10 }", null),
        arguments("if (1) { 10 }", 10),
        arguments("if (1 < 2) { 10 }", 10),
        arguments("if (1 > 2) { 10 }", null),
        arguments("if (1 > 2) { 10 } else { 20 }", 20),
        arguments("if (1 < 2) { 10 } else { 20 }", 10)
    )

    @ParameterizedTest
    @MethodSource
    fun ifElseExpression(input: String, expected: Int?) {
        val result = eval(input)

        if (expected is Int) {
            assertIs<MonkeyInteger>(result)
            assertEquals(expected, result.value)
        } else {
            assertEquals(MonkeyNull, result)
        }
    }

    private fun intExpression() = listOf(
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
        arguments("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50)
    )

    @ParameterizedTest
    @MethodSource
    fun intExpression(input: String, expected: Int) {
        val result = eval(input)

        assertIs<MonkeyInteger>(result)
        assertEquals(expected, result.value)
    }

    private fun letStatement() = listOf(
        arguments("let a = 5; a;", 5),
        arguments("let a = 5 * 5; a;", 25),
        arguments("let a = 5; let b = a; b;", 5),
        arguments("let a = 5; let b = a; let c = a + b + 5; c;", 15)
    )

    @ParameterizedTest
    @MethodSource
    fun letStatement(input: String, expected: Int) {
        val result = eval(input)

        assertIs<MonkeyInteger>(result)
        assertEquals(expected, result.value)
    }

    private fun returnStatement() = listOf(
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
        )
    )

    @ParameterizedTest
    @MethodSource
    fun returnStatement(input: String, expected: Int) {
        val result = eval(input)

        assertIs<MonkeyInteger>(result)
        assertEquals(expected, result.value)
    }

    private fun stringExpression() = listOf(
        arguments(
            """
                "Hello World!"
                """.trimIndent(),
            "Hello World!"
        ),
        arguments(""""Hello" + " " + "World"""", "Hello World")
    )

    @ParameterizedTest
    @MethodSource
    fun stringExpression(input: String, expected: String) {
        val result = eval(input)

        assertIs<MonkeyString>(result)
        assertEquals(expected, result.value)
    }
}
