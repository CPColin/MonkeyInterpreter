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
            listOf(ExpressionStatement(Identifier("foobar")))
        ),
        arguments(
            "5;",
            listOf(ExpressionStatement(IntegerLiteral(5)))
        ),
        arguments(
            "!5;",
            listOf(ExpressionStatement(PrefixExpression("!", IntegerLiteral(5))))
        ),
        arguments(
            "-15;",
            listOf(ExpressionStatement(PrefixExpression("-", IntegerLiteral(15))))
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
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "+", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "-", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "*", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "/", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), ">", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "<", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "==", IntegerLiteral(5))),
                ExpressionStatement(InfixExpression(IntegerLiteral(5), "!=", IntegerLiteral(5)))
            )
        ),
        arguments(
            "true != false;",
            listOf(ExpressionStatement(InfixExpression(BooleanLiteral(true), "!=", BooleanLiteral(false))))
        ),
        arguments(
            "if (x < y) { x }",
            listOf(
                ExpressionStatement(
                    IfExpression(
                        InfixExpression(Identifier("x"), "<", Identifier("y")),
                        BlockStatement(listOf(ExpressionStatement(Identifier("x")))),
                        null
                    )
                )
            )
        ),
        arguments(
            "if (x < y) { x } else { y }",
            listOf(
                ExpressionStatement(
                    IfExpression(
                        InfixExpression(Identifier("x"), "<", Identifier("y")),
                        BlockStatement(listOf(ExpressionStatement(Identifier("x")))),
                        BlockStatement(listOf(ExpressionStatement(Identifier("y"))))
                    )
                )
            )
        ),
        arguments(
            "fn() { 5; }",
            listOf(
                ExpressionStatement(
                    FunctionLiteral(
                        listOf(),
                        BlockStatement(
                            listOf(
                                ExpressionStatement(
                                    IntegerLiteral(5)
                                )
                            )
                        )
                    )
                )
            )
        ),
        arguments(
            "fn(x) {}",
            listOf(
                ExpressionStatement(
                    FunctionLiteral(
                        listOf(Identifier("x")),
                        BlockStatement(listOf())
                    )
                )
            )
        ),
        arguments(
            "fn(x, y) { x + y; }",
            listOf(
                ExpressionStatement(
                    FunctionLiteral(
                        listOf(Identifier("x"), Identifier("y")),
                        BlockStatement(
                            listOf(
                                ExpressionStatement(
                                    InfixExpression(Identifier("x"), "+", Identifier("y"))
                                )
                            )
                        )
                    )
                )
            )
        ),
        arguments(
            "add(1, 2 + 3)",
            listOf(
                ExpressionStatement(
                    CallExpression(
                        Identifier("add"),
                        listOf(
                            IntegerLiteral(1),
                            InfixExpression(IntegerLiteral(2), "+", IntegerLiteral(3))
                        )
                    )
                )
            )
        ),
        arguments(
            """
                "hello world"
                """.trimIndent(),
            listOf(
                ExpressionStatement(
                    StringLiteral("hello world")
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
