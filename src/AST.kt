interface Node {
    val string: String
}

interface Statement : Node

interface Expression : Node

data class Program(val statements: List<Statement>) : Node {
    override val string = statements.joinToString(separator = "", transform = Node::string)
}

data class BlockStatement(val statements: List<Statement>) : Statement {
    override val string = statements.joinToString { it.string }
}

data class BooleanLiteral(val value: Boolean) : Expression {
    override val string = value.toString()
}

data class CallExpression(val function: Expression?, val arguments: List<Expression>) : Expression {
    override val string = buildString {
        append(function?.string ?: "fn")
        arguments.joinTo(this, prefix = "(", separator = ", ", postfix = ")") { it.string }
    }
}

// TODO: What does this get us that having Expression implement Statement wouldn't?
data class ExpressionStatement(val value: Expression?) : Statement {
    override val string = value?.string ?: ""
}

data class FunctionLiteral(val parameters: List<Identifier>, val body: BlockStatement) : Expression {
    override val string = buildString {
        append("fn(")
        parameters.joinTo(buffer = this, separator = ", ") { it.string }
        append(") ")
        append(body.string)
    }
}

data class Identifier(val value: String) : Expression {
    override val string = value
}

data class IfExpression(
    val condition: Expression,
    val consequence: BlockStatement,
    val alternative: BlockStatement?
) : Expression {
    override val string: String
        get() = buildString {
            append("if ")
            append(condition.string)
            append(' ')
            append(consequence.string)

            if (alternative != null) {
                append("else ")
                append(alternative.string)
            }
        }
}

data class InfixExpression(val left: Expression?, val operator: String, val right: Expression?) : Expression {
    override val string = "(${left?.string} $operator ${right?.string})"
}

data class IntegerLiteral(val value: Int) : Expression {
    override val string = value.toString()
}

data class LetStatement(val name: Identifier, val value: Expression?) : Statement {
    override val string = "let ${name.string} = ${value?.string};"
}

data class PrefixExpression(val operator: String, val right: Expression?) : Expression {
    override val string = "($operator${right?.string})"
}

data class ReturnStatement(val value: Expression?) : Statement {
    override val string = "return ${value?.string};"
}
