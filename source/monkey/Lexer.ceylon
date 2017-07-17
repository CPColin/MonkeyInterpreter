shared class Lexer(input) {
    String input;
    
    variable Integer position = 0;
    
    variable Integer readPosition = 0;
    
    variable Character? character = null;
    
    shared Character? peekCharacter() => input[readPosition];
    
    shared void readCharacter() {
        character = input[readPosition];
        position = readPosition;
        readPosition++;
    }
    
    function isDigit(Character? character)
            => if (exists character)
                then '0' <= character <= '9'
                else false;
    
    function isLetter(Character? character)
            => if (exists character)
                then 'a' <= character <= 'z' || 'A' <= character <= 'Z' || character == '_'
                else false;
    
    function readLiteral(Boolean(Character?) predicate) {
        value start = position;
        
        while (predicate(character)) {
            readCharacter();
        }
        
        return input[start:position - start];
    }
    
    void skipWhitespace() {
        while (character?.whitespace else false) {
            readCharacter();
        }
    }
    
    shared Token nextToken() {
        skipWhitespace();
        
        TokenType type;
        value character = this.character;
        variable String? literalOverride = null;
        
        switch (character)
        case ('=') {
            if (exists peek = peekCharacter(), peek == '=') {
                readCharacter();
                type = TokenType.eq;
                literalOverride = "==";
            }
            else {
                type = TokenType.\iassign;
            }
        }
        case ('+') {
            type = TokenType.plus;
        }
        case ('-') {
            type = TokenType.minus;
        }
        case ('!') {
            if (exists peek = peekCharacter(), peek == '=') {
                readCharacter();
                type = TokenType.notEq;
                literalOverride = "!=";
            }
            else {
                type = TokenType.bang;
            }
        }
        case ('/') {
            type = TokenType.slash;
        }
        case ('*') {
            type = TokenType.asterisk;
        }
        case ('<') {
            type = TokenType.lt;
        }
        case ('>') {
            type = TokenType.gt;
        }
        case (';') {
            type = TokenType.semicolon;
        }
        case (',') {
            type = TokenType.comma;
        }
        case ('(') {
            type = TokenType.lparen;
        }
        case (')') {
            type = TokenType.rparen;
        }
        case ('{') {
            type = TokenType.lbrace;
        }
        case ('}') {
            type = TokenType.rbrace;
        }
        case (null) {
            type = TokenType.eof;
        }
        else {
            if (isLetter(character)) {
                value literal = readLiteral(isLetter);
                
                // Return early; readIdentifier already advanced our position.
                return Token(identifier(literal), literal);
            }
            else if (isDigit(character)) {
                value literal = readLiteral(isDigit);
                
                // Return early; readNumber already advanced our position.
                return Token(TokenType.int, literal);
            }
            else {
                type = TokenType.illegal;
            }
        }
        
        readCharacter();
        
        return Token(type, literalOverride else character?.string else "");
    }
    
    // Read the first character of the input.
    readCharacter();
}
