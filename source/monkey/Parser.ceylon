import ceylon.collection {
    ArrayList
}

shared class Parser(lexer) {
    Lexer lexer;
    
    variable Token currentToken = Token(TokenType.eof, "");
    
    variable Token peekToken = currentToken;
    
    value errorList = ArrayList<String>();
    
    void nextToken() {
        currentToken = peekToken;
        peekToken = lexer.nextToken();
    }
    
    nextToken();
    nextToken();
    
    function currentTokenIs(TokenType type) => currentToken.type == type;
    
    function peekTokenIs(TokenType type) => peekToken.type == type;
    
    function expectPeek(TokenType type) {
        if (peekTokenIs(type)) {
            nextToken();
            
            return true;
        }
        else {
            errorList.add("Expected next token to be ``type``, but found ``peekToken.type``");
            
            return false;
        }
    }
    
    function parseLetStatement() {
        value letToken = currentToken;
        
        if (!expectPeek(TokenType.ident)) {
            return null;
        }
        
        value identifier = Identifier(currentToken, currentToken.literal);
        
        if (!expectPeek(TokenType.\iassign)) {
            return null;
        }
        
        // TODO: skipping expression parsing for now
        while (!currentTokenIs(TokenType.semicolon)) {
            nextToken();
        }
        
        return LetStatement(letToken, identifier, null);
    }
    
    function parseStatement() {
        switch (currentToken.type)
        case (TokenType.\ilet) {
            return parseLetStatement();
        }
        else {
            return null;
        }
    }
    
    shared String[] errors => errorList.sequence();
    
    shared Program parseProgram() {
        value statements = ArrayList<Statement>();
        
        while (!currentTokenIs(TokenType.eof)) {
            value statement = parseStatement();
            
            if (exists statement) {
                statements.add(statement);
            }
            
            nextToken();
        }
        
        return Program(statements.sequence());
    }
}
