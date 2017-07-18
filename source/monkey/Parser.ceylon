import ceylon.collection {
    ArrayList
}

shared class Parser(lexer) {
    object precedence {
        shared Integer lowest = 0;
        
        shared Integer equality = 1;
        
        shared Integer lessGreater = 2;
        
        shared Integer sum = 3;
        
        shared Integer product = 4;
        
        shared Integer prefix = 5;
        
        shared Integer call = 6;
    }
    
    alias PrefixParser => Expression();
    
    alias InfixParser => Expression(Expression);
    
    Lexer lexer;
    
    variable Token currentToken = Token(TokenType.eof, "");
    
    variable Token peekToken = currentToken;
    
    value errorList = ArrayList<String>();
    
    void nextToken() {
        currentToken = peekToken;
        peekToken = lexer.nextToken();
    }
    
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
    
    function parseIdentifier() {
        return Identifier(currentToken, currentToken.literal);
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
    
    function parseReturnStatement() {
        value returnToken = currentToken;
        
        nextToken();
        
        // TODO: skipping expression parsing for now
        while (!currentTokenIs(TokenType.semicolon)) {
            nextToken();
        }
        
        return ReturnStatement(returnToken, null);
    }
    
    value prefixParsers = map {
        TokenType.ident -> parseIdentifier
    };
    
    value infixParsers = map {};
    
    function parseExpression(Integer precedence) {
        if (exists prefixParser = prefixParsers[currentToken.type]) {
            return prefixParser();
        }
        else {
            return null;
        }
    }
    
    function parseExpressionStatement() {
        value statement = ExpressionStatement(currentToken, parseExpression(precedence.lowest));
        
        if (peekTokenIs(TokenType.semicolon)) {
            nextToken();
        }
        
        return statement;
    }
    
    function parseStatement() {
        switch (currentToken.type)
        case (TokenType.\ilet) {
            return parseLetStatement();
        }
        case (TokenType.\ireturn) {
            return parseReturnStatement();
        }
        else {
            return parseExpressionStatement();
        }
    }
    
    nextToken();
    nextToken();
    
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
