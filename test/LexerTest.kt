import kotlin.test.Test
import kotlin.test.assertEquals

class LexerTest {
    @Test
    fun nextToken() {
        val input =
            """
                let five = 5;
                let ten = 10;

                let add = fn(x, y) {
                  x + y;
                };

                let result = add(five, ten);
                !-/*5;
                5 < 10 > 5;
                
                if (5 < 10) {
                    return true;
                } else {
                    return false;
                }
                
                10 == 10;
                10 != 9;
                "foobar"
                "foo bar"
                [1, 2];
                """.trimIndent()
        val expected = listOf(
            Token.Type.LET to "let",
            Token.Type.IDENT to "five",
            Token.Type.ASSIGN to "=",
            Token.Type.INT to "5",
            Token.Type.SEMICOLON to ";",
            Token.Type.LET to "let",
            Token.Type.IDENT to "ten",
            Token.Type.ASSIGN to "=",
            Token.Type.INT to "10",
            Token.Type.SEMICOLON to ";",
            Token.Type.LET to "let",
            Token.Type.IDENT to "add",
            Token.Type.ASSIGN to "=",
            Token.Type.FUNCTION to "fn",
            Token.Type.LPAREN to "(",
            Token.Type.IDENT to "x",
            Token.Type.COMMA to ",",
            Token.Type.IDENT to "y",
            Token.Type.RPAREN to ")",
            Token.Type.LBRACE to "{",
            Token.Type.IDENT to "x",
            Token.Type.PLUS to "+",
            Token.Type.IDENT to "y",
            Token.Type.SEMICOLON to ";",
            Token.Type.RBRACE to "}",
            Token.Type.SEMICOLON to ";",
            Token.Type.LET to "let",
            Token.Type.IDENT to "result",
            Token.Type.ASSIGN to "=",
            Token.Type.IDENT to "add",
            Token.Type.LPAREN to "(",
            Token.Type.IDENT to "five",
            Token.Type.COMMA to ",",
            Token.Type.IDENT to "ten",
            Token.Type.RPAREN to ")",
            Token.Type.SEMICOLON to ";",
            Token.Type.BANG to "!",
            Token.Type.MINUS to "-",
            Token.Type.SLASH to "/",
            Token.Type.ASTERISK to "*",
            Token.Type.INT to "5",
            Token.Type.SEMICOLON to ";",
            Token.Type.INT to "5",
            Token.Type.LT to "<",
            Token.Type.INT to "10",
            Token.Type.GT to ">",
            Token.Type.INT to "5",
            Token.Type.SEMICOLON to ";",
            Token.Type.IF to "if",
            Token.Type.LPAREN to "(",
            Token.Type.INT to "5",
            Token.Type.LT to "<",
            Token.Type.INT to "10",
            Token.Type.RPAREN to ")",
            Token.Type.LBRACE to "{",
            Token.Type.RETURN to "return",
            Token.Type.TRUE to "true",
            Token.Type.SEMICOLON to ";",
            Token.Type.RBRACE to "}",
            Token.Type.ELSE to "else",
            Token.Type.LBRACE to "{",
            Token.Type.RETURN to "return",
            Token.Type.FALSE to "false",
            Token.Type.SEMICOLON to ";",
            Token.Type.RBRACE to "}",
            Token.Type.INT to "10",
            Token.Type.EQ to "==",
            Token.Type.INT to "10",
            Token.Type.SEMICOLON to ";",
            Token.Type.INT to "10",
            Token.Type.NOT_EQ to "!=",
            Token.Type.INT to "9",
            Token.Type.SEMICOLON to ";",
            Token.Type.STRING to "foobar",
            Token.Type.STRING to "foo bar",
            Token.Type.LBRACKET to "[",
            Token.Type.INT to "1",
            Token.Type.COMMA to ",",
            Token.Type.INT to "2",
            Token.Type.RBRACKET to "]",
            Token.Type.SEMICOLON to ";",
            Token.Type.EOF to ""
        )

        val lexer = Lexer(input)

        for ((expectedType, expectedLiteral) in expected) {
            assertEquals(Token(expectedLiteral, expectedType), lexer.nextToken())
        }
    }
}
