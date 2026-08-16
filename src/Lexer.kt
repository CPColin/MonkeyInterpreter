import Token.Type

class Lexer(private val input: String) {
    private var current = '\u0000'
    private var position = -1
    private var readPosition = 0

    init {
        readChar()
    }

    fun nextToken(): Token {
        skipWhitespace()

        return when (current) {
            '=' -> {
                if (peekChar('=')) {
                    Token("==", Type.EQ)
                } else {
                    Token("=", Type.ASSIGN)
                }
            }
            '+' -> Token("+", Type.PLUS)
            '-' -> Token("-", Type.MINUS)
            '!' -> {
                if (peekChar('=')) {
                    Token("!=", Type.NOT_EQ)
                } else {
                    Token("!", Type.BANG)
                }
            }
            '/' -> Token("/", Type.SLASH)
            '*' -> Token("*", Type.ASTERISK)
            '<' -> Token("<", Type.LT)
            '>' -> Token(">", Type.GT)
            ';' -> Token(";", Type.SEMICOLON)
            ',' -> Token(",", Type.COMMA)
            '(' -> Token("(", Type.LPAREN)
            ')' -> Token(")", Type.RPAREN)
            '{' -> Token("{", Type.LBRACE)
            '}' -> Token("}", Type.RBRACE)
            '[' -> Token("[", Type.LBRACKET)
            ']' -> Token("]", Type.RBRACKET)
            ':' -> Token(":", Type.COLON)
            '"' -> Token(readString(), Type.STRING)
            '\u0000' -> Token("", Type.EOF)
            else -> {
                if (isLetter(current)) {
                    readIdentifier().let {
                        return@nextToken Token(it, KEYWORDS[it] ?: Type.IDENT)
                    }
                } else if (isDigit(current)) {
                    readNumber().let {
                        return@nextToken Token(it, Type.INT)
                    }
                } else {
                    Token("", Type.ILLEGAL)
                }
            }
        }.also {
            readChar()
        }
    }

    fun peekChar(target: Char) =
        if (readPosition < input.length && input[readPosition] == target) {
            readChar()
            true
        } else {
            false
        }

    fun readChar() {
        current = input.getOrElse(readPosition) { '\u0000' }
        position = readPosition
        readPosition++
    }

    fun readIdentifier(): String {
        val start = position

        while (isLetter(current)) {
            readChar()
        }

        return input.substring(start..<position)
    }

    fun readNumber(): String {
        val start = position

        while (isDigit(current)) {
            readChar()
        }

        return input.substring(start..<position)
    }

    fun readString(): String {
        val start = position + 1

        do {
            readChar()
        } while (current != '"' && current != '\u0000')

        return input.substring(start..<position)
    }

    fun skipWhitespace() {
        while (current in " \t\n\r") {
            readChar()
        }
    }

    companion object {
        val KEYWORDS = mapOf(
            "else" to Type.ELSE,
            "false" to Type.FALSE,
            "fn" to Type.FUNCTION,
            "if" to Type.IF,
            "let" to Type.LET,
            "return" to Type.RETURN,
            "true" to Type.TRUE
        )

        private fun isDigit(character: Char) = character in '0'..'9'

        private fun isLetter(character: Char) =
            character in 'a'..'z' || character in 'A'..'Z' || character == '_'
    }
}
