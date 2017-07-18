import ceylon.test {
    assertEquals,
    test
}

import monkey {
    Identifier,
    LetStatement,
    Program,
    Token,
    TokenType
}

test
shared void testString() {
    value program = Program([
        LetStatement {
            token = Token(TokenType.\ilet, "let");
            name = Identifier {
                token = Token(TokenType.ident, "myVar");
                val = "myVar";
            };
            val = Identifier {
                token = Token(TokenType.ident, "anotherVar");
                val = "anotherVar";
            };
        }
    ]);
    
    assertEquals(program.string, "let myVar = anotherVar;");
}
