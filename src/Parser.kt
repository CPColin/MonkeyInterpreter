class Parser(private val lexer: Lexer) {
    enum class Precedence {
        LOWEST,
        EQUALS,
        COMPARE,
        SUM,
        PRODUCT,
        PREFIX,
        CALL,
        INDEX
    }

    private var currentToken = Token("", Token.Type.EOF)

    private var peekToken = Token("", Token.Type.EOF)

    val errors = mutableListOf<String>()

    private val statements = mutableListOf<Statement>()

    init {
        nextToken()
        nextToken()
    }

    fun currentPrecedence() = precedences[currentToken.type] ?: Precedence.LOWEST

    fun expectPeek(type: Token.Type) =
        if (peekToken.type == type) {
            nextToken()
            true
        } else {
            errors.add("Expected next token to be $type, but found ${peekToken.type}")
            false
        }

    fun nextToken() {
        currentToken = peekToken
        peekToken = lexer.nextToken()
    }

    fun parseArrayLiteral(): ArrayLiteral {
        return ArrayLiteral(parseExpressionList(Token.Type.RBRACKET))
    }

    fun parseBlockStatement(): BlockStatement {
        nextToken()

        val statements = buildList {
            while (currentToken.type != Token.Type.RBRACE && currentToken.type != Token.Type.EOF) {
                parseStatement()?.run { add(this) }
                nextToken()
            }
        }

        return BlockStatement(statements)
    }

    fun parseBooleanLiteral(): BooleanLiteral? {
        val value = currentToken.literal.toBooleanStrictOrNull()

        if (value == null) {
            errors.add("Could not parse ${currentToken.literal} as boolean")
        }

        return value?.let { BooleanLiteral(value) }
    }

    fun parseCallExpression(function: Expression?): CallExpression {
        return CallExpression(function, parseExpressionList(Token.Type.RPAREN))
    }

    fun <T> parseElementList(endTokenType: Token.Type, parser: () -> T?): List<T> {
        nextToken()

        return buildList {
            while (currentToken.type != endTokenType && currentToken.type != Token.Type.EOF) {
                parser()?.run { add(this) }
                nextToken()

                if (currentToken.type == Token.Type.COMMA) {
                    nextToken()
                } else if (currentToken.type != endTokenType) {
                    errors.add("Expected another element or $endTokenType")
                    nextToken()
                    break
                }
            }
        }
    }

    fun parseExpression(precedence: Precedence): Expression? {
        val prefixParser = prefixParsers[currentToken.type]

        if (prefixParser == null) {
            errors.add("No prefix parser found for ${currentToken.type}")
        }

        var left = prefixParser?.invoke(this)

        while (peekToken.type != Token.Type.SEMICOLON && precedence < peekPrecedence()) {
            val infixParser = infixParsers[peekToken.type] ?: break

            nextToken()

            left = infixParser.invoke(this, left)
        }

        return left
    }

    fun parseExpressionList(endTokenType: Token.Type): List<Expression> =
        parseElementList(endTokenType) { parseExpression(Precedence.LOWEST) }

    fun parseExpressionStatement() =
        ExpressionStatement(parseExpression(Precedence.LOWEST)).also {
            if (peekToken.type == Token.Type.SEMICOLON) {
                nextToken()
            }
        }

    fun parseFunctionLiteral(): Expression? {
        if (!expectPeek(Token.Type.LPAREN)) {
            return null
        }

        val parameters = parseFunctionParameters()

        if (!expectPeek(Token.Type.LBRACE)) {
            return null
        }

        val body = parseBlockStatement()

        return FunctionLiteral(parameters, body)
    }

    fun parseFunctionParameters(): List<Identifier> = parseElementList(Token.Type.RPAREN) { parseIdentifier() }

    fun parseGroupedExpression(): Expression? {
        nextToken()

        val expression = parseExpression(Precedence.LOWEST)

        if (!expectPeek(Token.Type.RPAREN)) {
            return null
        }

        return expression
    }

    fun parseIdentifier() = Identifier(currentToken.literal)

    fun parseIfExpression(): Expression? {
        if (!expectPeek(Token.Type.LPAREN)) {
            return null
        }

        nextToken()

        val condition = parseExpression(Precedence.LOWEST)

        if (condition == null || !expectPeek(Token.Type.RPAREN) || !expectPeek(Token.Type.LBRACE)) {
            return null
        }

        val consequence = parseBlockStatement()

        val alternative = if (peekToken.type == Token.Type.ELSE) {
            nextToken()

            if (!expectPeek(Token.Type.LBRACE)) {
                return null
            }

            parseBlockStatement()
        } else {
            null
        }

        return IfExpression(condition, consequence, alternative)
    }

    fun parseIndexExpression(left: Expression?): Expression? {
        nextToken()

        val index = parseExpression(Precedence.LOWEST)

        if (!expectPeek(Token.Type.RBRACKET)) {
            return null
        }

        return IndexExpression(left, index)
    }

    fun parseInfixExpression(left: Expression?): InfixExpression? {
        val operator = InfixExpression.Operator.fromLiteral(currentToken.literal)

        if (operator == null) {
            errors.add("Unsupported infix operator: ${currentToken.literal}")
        }

        val precedence = currentPrecedence()

        nextToken()

        val right = parseExpression(precedence)

        return operator?.let { InfixExpression(left, operator, right) }
    }

    fun parseIntegerLiteral(): IntegerLiteral? {
        val value = currentToken.literal.toIntOrNull()

        if (value == null) {
            errors.add("Could not parse ${currentToken.literal} as integer")
        }

        return value?.let { IntegerLiteral(value) }
    }

    fun parseLetStatement(): LetStatement? {
        if (!expectPeek(Token.Type.IDENT)) {
            return null
        }

        val name = Identifier(currentToken.literal)

        if (!expectPeek(Token.Type.ASSIGN)) {
            return null
        }

        nextToken()

        val value = parseExpression(Precedence.LOWEST)

        if (peekToken.type == Token.Type.SEMICOLON) {
            nextToken()
        }

        return LetStatement(name, value)
    }

    fun parsePrefixExpression(): PrefixExpression? {
        val operator = PrefixExpression.Operator.fromLiteral(currentToken.literal)

        if (operator == null) {
            errors.add("Unsupported prefix operator: ${currentToken.literal}")
        }

        nextToken()

        val right = parseExpression(Precedence.PREFIX)

        return operator?.let { PrefixExpression(operator, right) }
    }

    fun parseProgram(): Program {
        while (currentToken.type != Token.Type.EOF) {
            val statement = parseStatement()

            if (statement != null) {
                statements.add(statement)
            }

            nextToken()
        }

        return Program(statements)
    }

    fun parseReturnStatement(): ReturnStatement {
        nextToken()

        val expression = parseExpression(Precedence.LOWEST)

        if (peekToken.type == Token.Type.SEMICOLON) {
            nextToken()
        }

        return ReturnStatement(expression)
    }

    fun parseStatement() =
        when (currentToken.type) {
            Token.Type.LET -> parseLetStatement()
            Token.Type.RETURN -> parseReturnStatement()
            else -> parseExpressionStatement()
        }

    fun parseStringLiteral() = StringLiteral(currentToken.literal)

    fun peekPrecedence() = precedences[peekToken.type] ?: Precedence.LOWEST

    companion object {
        private val infixParsers: Map<Token.Type, (Parser, Expression?) -> Expression?> = mapOf(
            Token.Type.ASTERISK to Parser::parseInfixExpression,
            Token.Type.EQ to Parser::parseInfixExpression,
            Token.Type.GT to Parser::parseInfixExpression,
            Token.Type.LBRACKET to Parser::parseIndexExpression,
            Token.Type.LPAREN to Parser::parseCallExpression,
            Token.Type.LT to Parser::parseInfixExpression,
            Token.Type.MINUS to Parser::parseInfixExpression,
            Token.Type.NOT_EQ to Parser::parseInfixExpression,
            Token.Type.PLUS to Parser::parseInfixExpression,
            Token.Type.SLASH to Parser::parseInfixExpression
        )

        private val precedences= mapOf(
            Token.Type.EQ to Precedence.EQUALS,
            Token.Type.NOT_EQ to Precedence.EQUALS,
            Token.Type.LPAREN to Precedence.CALL,
            Token.Type.LT to Precedence.COMPARE,
            Token.Type.GT to Precedence.COMPARE,
            Token.Type.PLUS to Precedence.SUM,
            Token.Type.MINUS to Precedence.SUM,
            Token.Type.SLASH to Precedence.PRODUCT,
            Token.Type.ASTERISK to Precedence.PRODUCT,
            Token.Type.LBRACKET to Precedence.INDEX
        )

        private val prefixParsers: Map<Token.Type, (Parser) -> Expression?> = mapOf(
            Token.Type.BANG to Parser::parsePrefixExpression,
            Token.Type.FALSE to Parser::parseBooleanLiteral,
            Token.Type.FUNCTION to Parser::parseFunctionLiteral,
            Token.Type.IDENT to Parser::parseIdentifier,
            Token.Type.IF to Parser::parseIfExpression,
            Token.Type.INT to Parser::parseIntegerLiteral,
            Token.Type.LBRACKET to Parser::parseArrayLiteral,
            Token.Type.LPAREN to Parser::parseGroupedExpression,
            Token.Type.MINUS to Parser::parsePrefixExpression,
            Token.Type.STRING to Parser::parseStringLiteral,
            Token.Type.TRUE to Parser::parseBooleanLiteral
        )
    }
}
