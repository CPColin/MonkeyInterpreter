data class Token(
    val literal: String,
    val type: Type
) {
    enum class Type {
        ILLEGAL,
        EOF,
        IDENT,
        INT,

        // Operators
        ASSIGN,
        ASTERISK,
        BANG,
        EQ,
        GT,
        LT,
        MINUS,
        NOT_EQ,
        PLUS,
        SLASH,

        // Punctuation
        COMMA,
        SEMICOLON,
        LPAREN,
        RPAREN,
        LBRACE,
        RBRACE,

        // Keywords
        ELSE,
        FALSE,
        FUNCTION,
        IF,
        LET,
        RETURN,
        TRUE,
    }
}
