import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments.arguments
import org.junit.jupiter.params.provider.MethodSource
import kotlin.test.assertEquals

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ParserTest {
    private fun parseProgram() = listOf(
        arguments(
            """
                let x = 5;
                let y = 10;
                let foobar = 838383;
                """.trimIndent(),
            listOf(
                LetStatement(Identifier("x"), IntegerLiteral(5)),
                LetStatement(Identifier("y"), IntegerLiteral(10)),
                LetStatement(Identifier("foobar"), IntegerLiteral(838383))
            )
        ),
        arguments(
            """
                return 5;
                return 10;
                return 993322;
                """.trimIndent(),
            listOf(
                ReturnStatement(IntegerLiteral(5)),
                ReturnStatement(IntegerLiteral(10)),
                ReturnStatement(IntegerLiteral(993322))
            )
        ),
        arguments(
            "foobar;",
            listOf(Identifier("foobar"))
        ),
        arguments(
            "5;",
            listOf(IntegerLiteral(5))
        ),
        arguments(
            "!5;",
            listOf(PrefixExpression(PrefixExpression.Operator.`!`, IntegerLiteral(5)))
        ),
        arguments(
            "-15;",
            listOf(PrefixExpression(PrefixExpression.Operator.`-`, IntegerLiteral(15)))
        ),
        arguments(
            """
                5 + 5;
                5 - 5;
                5 * 5;
                5 / 5;
                5 > 5;
                5 < 5;
                5 == 5;
                5 != 5;
                """.trimIndent(),
            listOf(
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.PLUS, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.MINUS, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.MULTIPLY, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.DIVIDE, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.GREATER_THAN, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.LESS_THAN, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.EQUALS, IntegerLiteral(5)),
                InfixExpression(IntegerLiteral(5), InfixExpression.Operator.NOT_EQUALS, IntegerLiteral(5))
            )
        ),
        arguments(
            "true != false;",
            listOf(
                InfixExpression(BooleanLiteral(true), InfixExpression.Operator.NOT_EQUALS, BooleanLiteral(false))
            )
        ),
        arguments(
            "if (x < y) { x }",
            listOf(
                IfExpression(
                    InfixExpression(Identifier("x"), InfixExpression.Operator.LESS_THAN, Identifier("y")),
                    BlockStatement(listOf(Identifier("x"))),
                    null
                )
            )
        ),
        arguments(
            "if (x < y) { x } else { y }",
            listOf(
                IfExpression(
                    InfixExpression(Identifier("x"), InfixExpression.Operator.LESS_THAN, Identifier("y")),
                    BlockStatement(listOf(Identifier("x"))),
                    BlockStatement(listOf(Identifier("y")))
                )
            )
        ),
        arguments(
            "fn() { 5; }",
            listOf(FunctionLiteral(emptyList(), BlockStatement(listOf(IntegerLiteral(5)))))
        ),
        arguments(
            "fn(x) {}",
            listOf(FunctionLiteral(listOf(Identifier("x")), BlockStatement(listOf())))
        ),
        arguments(
            "fn(x, y) { x + y; }",
            listOf(
                FunctionLiteral(
                    listOf(Identifier("x"), Identifier("y")),
                    BlockStatement(
                        listOf(InfixExpression(Identifier("x"), InfixExpression.Operator.PLUS, Identifier("y")))
                    )
                )
            )
        ),
        arguments(
            "add(1, 2 + 3)",
            listOf(
                CallExpression(
                    Identifier("add"),
                    listOf(
                        IntegerLiteral(1),
                        InfixExpression(IntegerLiteral(2), InfixExpression.Operator.PLUS, IntegerLiteral(3))
                    )
                )
            )
        ),
        arguments(
            """
                "hello world"
                """.trimIndent(),
            listOf(StringLiteral("hello world"))
        ),
        arguments(
            "[]",
            listOf(ArrayLiteral(emptyList()))
        ),
        arguments(
            "[1, 2 + 2, 3 * 3]",
            listOf(
                ArrayLiteral(
                    listOf(
                        IntegerLiteral(1),
                        InfixExpression(IntegerLiteral(2), InfixExpression.Operator.PLUS, IntegerLiteral(2)),
                        InfixExpression(IntegerLiteral(3), InfixExpression.Operator.MULTIPLY, IntegerLiteral(3))
                    )
                )
            )
        ),
        arguments(
            "myArray[1 + 2]",
            listOf(
                IndexExpression(
                    Identifier("myArray"),
                    InfixExpression(IntegerLiteral(1), InfixExpression.Operator.PLUS, IntegerLiteral(2)),
                )
            )
        ),
        arguments(
            """{"one": 1, "two": 2, "three": 3}""",
            listOf(
                HashLiteral(
                    listOf(
                        StringLiteral("one") to IntegerLiteral(1),
                        StringLiteral("two") to IntegerLiteral(2),
                        StringLiteral("three") to IntegerLiteral(3)
                    )
                )
            )
        )
    )

    @ParameterizedTest
    @MethodSource
    fun parseProgram(input: String, expectedStatements: List<Statement>) {
        val parser = Parser(Lexer(input))
        val program = parser.parseProgram()

        assertEquals(listOf(), parser.errors, "Parser has errors")
        assertEquals(expectedStatements.size, program.statements.size, "Parsed program is wrong length")

        for ((index, expectedStatement) in expectedStatements.withIndex()) {
            assertEquals(expectedStatement, program.statements[index], "Statement at index $index does not match")
        }
    }

    private fun precedence() = listOf(
        arguments(
            "-a * b",
            "((-a) * b)",
        ),
        arguments(
            "!-a",
            "(!(-a))"
        ),
        arguments(
            "a + b + c",
            "((a + b) + c)"
        ),
        arguments(
            "a + b - c",
            "((a + b) - c)"
        ),
        arguments(
            "3 + 4; -5 * 5",
            "(3 + 4)((-5) * 5)"
        ),
        arguments(
            "3 + 4 * 5 == 3 * 1 + 4 * 5",
            "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"
        ),
        arguments(
            "3 > 5 == false",
            "((3 > 5) == false)"
        ),
        arguments(
            "1 + (2 + 3) + 4",
            "((1 + (2 + 3)) + 4)"
        ),
        arguments(
            "2 / (5 + 5)",
            "(2 / (5 + 5))"
        ),
        arguments(
            "a + add(b * c) + d",
            "((a + add((b * c))) + d)"
        ),
        arguments(
            "a * [1, 2, 3, 4][b * c] * d",
            "((a * ([1, 2, 3, 4][(b * c)])) * d)"
        ),
        arguments(
            "add(a * b[2], b[1], 2 * [1, 2][1])",
            "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
        )
    )

    @ParameterizedTest
    @MethodSource
    fun precedence(input: String, expected: String) {
        val parser = Parser(Lexer(input))
        val program = parser.parseProgram()

        assertEquals(emptyList(), parser.errors, "Parser has errors")
        assertEquals(expected, program.string)
    }
}
