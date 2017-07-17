import ceylon.test {
    assertEquals,
    test
}

import monkey {
    Lexer,
    TokenType
}

test
shared void testNextToken() {
    value input = "let five = 5;
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
                   ";
    
    value expectedTokens = {
        [ TokenType.\ilet, "let" ],
        [ TokenType.ident, "five" ],
        [ TokenType.\iassign, "=" ],
        [ TokenType.int, "5" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.\ilet, "let" ],
        [ TokenType.ident, "ten" ],
        [ TokenType.\iassign, "=" ],
        [ TokenType.int, "10" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.\ilet, "let" ],
        [ TokenType.ident, "add" ],
        [ TokenType.\iassign, "=" ],
        [ TokenType.\ifunction, "fn" ],
        [ TokenType.lparen, "(" ],
        [ TokenType.ident, "x" ],
        [ TokenType.comma, "," ],
        [ TokenType.ident, "y" ],
        [ TokenType.rparen, ")" ],
        [ TokenType.lbrace, "{" ],
        [ TokenType.ident, "x" ],
        [ TokenType.plus, "+" ],
        [ TokenType.ident, "y" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.rbrace, "}" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.\ilet, "let" ],
        [ TokenType.ident, "result" ],
        [ TokenType.\iassign, "=" ],
        [ TokenType.ident, "add" ],
        [ TokenType.lparen, "(" ],
        [ TokenType.ident, "five" ],
        [ TokenType.comma, "," ],
        [ TokenType.ident, "ten" ],
        [ TokenType.rparen, ")" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.bang, "!" ],
        [ TokenType.minus, "-" ],
        [ TokenType.slash, "/" ],
        [ TokenType.asterisk, "*" ],
        [ TokenType.int, "5" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.int, "5" ],
        [ TokenType.lt, "<" ],
        [ TokenType.int, "10" ],
        [ TokenType.gt, ">" ],
        [ TokenType.int, "5" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.\iif, "if" ],
        [ TokenType.lparen, "(" ],
        [ TokenType.int, "5" ],
        [ TokenType.lt, "<" ],
        [ TokenType.int, "10" ],
        [ TokenType.rparen, ")" ],
        [ TokenType.lbrace, "{" ],
        [ TokenType.\ireturn, "return" ],
        [ TokenType.\itrue, "true" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.rbrace, "}" ],
        [ TokenType.\ielse, "else" ],
        [ TokenType.lbrace, "{" ],
        [ TokenType.\ireturn, "return" ],
        [ TokenType.\ifalse, "false" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.rbrace, "}" ],
        [ TokenType.int, "10" ],
        [ TokenType.eq, "==" ],
        [ TokenType.int, "10" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.int, "10" ],
        [ TokenType.notEq, "!=" ],
        [ TokenType.int, "9" ],
        [ TokenType.semicolon, ";" ],
        [ TokenType.eof, "" ]
    };
    
    value lexer = Lexer(input);
    variable Integer count = 0;
    
    for ([expectedType, expectedLiteral] in expectedTokens) {
        count++;
        
        value token = lexer.nextToken();
        
        //print("``count``: ``token``");
        
        assertEquals(token.type, expectedType, "Incorrect token type at index ``count``");
        assertEquals(token.literal, expectedLiteral, "Incorrect token literal at index ``count``");
    }
}
