import ceylon.collection {
    ArrayList
}

shared class Parser(lexer) {
    object precedence satisfies Correspondence<TokenType, Integer> {
        shared Integer lowest = 0;
        
        shared Integer equality = 1;
        
        shared Integer lessGreater = 2;
        
        shared Integer sum = 3;
        
        shared Integer product = 4;
        
        shared Integer prefix = 5;
        
        shared Integer call = 6;
        
        value precedences = map {
            TokenType.eq -> equality,
            TokenType.notEq -> equality,
            TokenType.lparen -> call,
            TokenType.lt -> lessGreater,
            TokenType.gt -> lessGreater,
            TokenType.plus -> sum,
            TokenType.minus -> sum,
            TokenType.asterisk -> product,
            TokenType.slash -> product
        };
        
        get(TokenType type) => precedences[type];
        
        defines(TokenType type) => precedences.defines(type);
    }
    
    alias PrefixParser => Expression?();
    
    alias InfixParser => Expression?(Expression?);
    
    Lexer lexer;
    
    variable Token currentToken = Token(TokenType.eof, "");
    
    variable Token peekToken = currentToken;
    
    value errorList = ArrayList<String>();
    
    late Map<TokenType, PrefixParser> prefixParsers;
    
    late Map<TokenType, InfixParser> infixParsers;
    
    value currentPrecedence => precedence[currentToken.type] else precedence.lowest;
    
    function currentTokenIs(TokenType type) => currentToken.type == type;
    
    value peekPrecedence => precedence[peekToken.type] else precedence.lowest;
    
    function peekTokenIs(TokenType type) => peekToken.type == type;
    
    void nextToken() {
        currentToken = peekToken;
        peekToken = lexer.nextToken();
    }
    
    function parseExpression(Integer precedence) {
        value prefixParser = prefixParsers[currentToken.type];
        
        if (!exists prefixParser) {
            errorList.add("No prefix parser found for ``currentToken.type``");
            
            return null;
        }
        
        variable value left = prefixParser();
        
        while (!peekTokenIs(TokenType.semicolon) && precedence < peekPrecedence) {
            value infixParser = infixParsers[peekToken.type];
            
            if (!exists infixParser) {
                return left;
            }
            
            nextToken();
            
            left = infixParser(left);
        }
        
        return left;
    }
    
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
    
    function parseBooleanLiteral() {
        return BooleanLiteral(currentToken, currentTokenIs(TokenType.true));
    }
    
    function parseGroupedExpression() {
        nextToken();
        
        value expression = parseExpression(precedence.lowest);
        
        if (!expectPeek(TokenType.rparen)) {
            return null;
        }
        
        return expression;
    }
    
    function parseIdentifier() {
        return Identifier(currentToken, currentToken.literal);
    }
    
    function parseInfixExpression(Expression? left) {
        value operatorToken = currentToken;
        value precedence = currentPrecedence;
        
        nextToken();
        
        value right = parseExpression(precedence);
        
        return InfixExpression(operatorToken, left, operatorToken.literal, right);
    }
    
    function parseIntegerLiteral() {
        value val = Integer.parse(currentToken.literal);
        
        if (is Integer val) {
            return IntegerLiteral(currentToken, val);
        }
        else {
            errorList.add("Could not parse ``currentToken.literal`` as integer");
            
            return null;
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
        
        nextToken();
        
        value val = parseExpression(precedence.lowest);
        
        if (peekTokenIs(TokenType.semicolon)) {
            nextToken();
        }
        
        return LetStatement(letToken, identifier, val);
    }
    
    function parsePrefixExpression() {
        value token = currentToken;
        
        nextToken();
        
        value right = parseExpression(precedence.prefix);
        
        return PrefixExpression(token, token.literal, right);
    }
    
    function parseReturnStatement() {
        value returnToken = currentToken;
        
        nextToken();
        
        value returnValue = parseExpression(precedence.lowest);
        
        if (peekTokenIs(TokenType.semicolon)) {
            nextToken();
        }
        
        return ReturnStatement(returnToken, returnValue);
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
    
    function parseBlockStatement() {
        value blockToken = currentToken;
        value statements = ArrayList<Statement>();
        
        nextToken();
        
        while (!currentTokenIs(TokenType.rbrace) && !currentTokenIs(TokenType.eof)) {
            value statement = parseStatement();
            
            if (exists statement) {
                statements.add(statement);
            }
            
            nextToken();
        }
        
        return BlockStatement(blockToken, statements.sequence());
    }
    
    function parseCallArguments() {
        if (peekTokenIs(TokenType.rparen)) {
            nextToken();
            
            return empty;
        }
        
        nextToken();
        
        value arguments = ArrayList<Expression?>();
        
        arguments.add(parseExpression(precedence.lowest));
        
        while (peekTokenIs(TokenType.comma)) {
            nextToken();
            nextToken();
            arguments.add(parseExpression(precedence.lowest));
        }
        
        if (!expectPeek(TokenType.rparen)) {
            return null;
        }
        
        return arguments.coalesced.sequence();
    }
    
    function parseCallExpression(Expression? left) {
        value callToken = currentToken;
        value arguments = parseCallArguments();
        
        return CallExpression(callToken, left, arguments);
    }
    
    function parseFunctionParameters() {
        if (peekTokenIs(TokenType.rparen)) {
            nextToken();
            
            return empty;
        }
        
        value identifiers = ArrayList<Identifier>();
        
        nextToken();
        
        identifiers.add(Identifier(currentToken, currentToken.literal));
        
        while (peekTokenIs(TokenType.comma)) {
            nextToken();
            nextToken();
            identifiers.add(Identifier(currentToken, currentToken.literal));
        }
        
        if (!expectPeek(TokenType.rparen)) {
            return null;
        }
        
        return identifiers.sequence();
    }
    
    function parseFunctionLiteral() {
        value functionToken = currentToken;
        
        if (!expectPeek(TokenType.lparen)) {
            return null;
        }
        
        value parameters = parseFunctionParameters();
        
        if (!exists parameters) {
            return null;
        }
        
        if (!expectPeek(TokenType.lbrace)) {
            return null;
        }
        
        value body = parseBlockStatement();
        
        return FunctionLiteral(functionToken, parameters, body);
    }
    
    function parseIfExpression() {
        value ifToken = currentToken;
        
        if (!expectPeek(TokenType.lparen)) {
            return null;
        }
        
        nextToken();
        
        value condition = parseExpression(precedence.lowest);
        
        if (!expectPeek(TokenType.rparen)) {
            return null;
        }
        
        if (!expectPeek(TokenType.lbrace)) {
            return null;
        }
        
        value consequence = parseBlockStatement();
        BlockStatement? alternative;
        
        if (peekTokenIs(TokenType.\ielse)) {
            nextToken();
            
            if (!expectPeek(TokenType.lbrace)) {
                return null;
            }
            
            alternative = parseBlockStatement();
        }
        else {
            alternative = null;
        }
        
        return IfExpression(ifToken, condition, consequence, alternative);
    }
    
    prefixParsers = map {
        TokenType.bang -> parsePrefixExpression,
        TokenType.false -> parseBooleanLiteral,
        TokenType.\ifunction -> parseFunctionLiteral,
        TokenType.ident -> parseIdentifier,
        TokenType.\iif -> parseIfExpression,
        TokenType.int -> parseIntegerLiteral,
        TokenType.lparen -> parseGroupedExpression,
        TokenType.minus -> parsePrefixExpression,
        TokenType.true -> parseBooleanLiteral
    };
    
    infixParsers = map {
        TokenType.asterisk -> parseInfixExpression,
        TokenType.eq -> parseInfixExpression,
        TokenType.gt -> parseInfixExpression,
        TokenType.lparen -> parseCallExpression,
        TokenType.lt -> parseInfixExpression,
        TokenType.minus -> parseInfixExpression,
        TokenType.notEq -> parseInfixExpression,
        TokenType.plus -> parseInfixExpression,
        TokenType.slash -> parseInfixExpression
    };
    
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
