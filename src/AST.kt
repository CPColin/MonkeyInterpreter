@file:Suppress("EnumEntryName")

sealed interface Node {
    val string: String
}

sealed interface Statement : Node

sealed interface Expression : Statement

data class Program(val statements: List<Statement>) : Node {
    override val string = statements.joinToString(separator = "", transform = Node::string)
}

data class ArrayLiteral(val elements: List<Expression>) : Expression {
    override val string = elements.joinToString(prefix = "[", separator = ", ", postfix = "]") { it.string }
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

data class IndexExpression(val left: Expression?, val index: Expression?) : Expression {
    override val string = "(${left?.string}[${index?.string}])"
}

data class InfixExpression(val left: Expression?, val operator: Operator, val right: Expression?) : Expression {
    // I wanted to make these look like `+`, `-`, etc., but `<` caused the compiler to freak out!
    enum class Operator(private val literal: String) {
        PLUS("+"),
        MINUS("-"),
        MULTIPLY("*"),
        DIVIDE("/"),
        LESS_THAN("<"),
        GREATER_THAN(">"),
        EQUALS("=="),
        NOT_EQUALS("!=");

        override fun toString() = literal

        companion object {
            fun fromLiteral(literal: String) = Operator.entries.find { it.literal == literal }
        }
    }

    override val string = "(${left?.string} $operator ${right?.string})"
}

data class IntegerLiteral(val value: Int) : Expression {
    override val string = value.toString()
}

data class LetStatement(val name: Identifier, val value: Expression?) : Statement {
    override val string = "let ${name.string} = ${value?.string};"
}

data class PrefixExpression(val operator: Operator, val right: Expression?) : Expression {
    enum class Operator {
        `!`,
        `-`;

        companion object {
            fun fromLiteral(literal: String) = entries.find { it.name == literal }
        }
    }

    override val string = "($operator${right?.string})"
}

data class ReturnStatement(val value: Expression?) : Statement {
    override val string = "return ${value?.string};"
}

data class StringLiteral(val value: String) : Expression {
    override val string = "\"$value\""
}
