@file:Suppress("IfThenToElvis")

import kotlin.collections.map


context(environment: Environment)
fun eval(node: Node?): MonkeyObject =
    when (node) {
        is ArrayLiteral -> evalArrayLiteral(node)
        is BlockStatement -> evalBlockStatement(node)
        is BooleanLiteral -> MonkeyBoolean(node.value)
        is CallExpression -> evalCallExpression(node)
        is FunctionLiteral -> MonkeyFunction(node, environment)
        is HashLiteral -> evalHashLiteral(node)
        is Identifier -> evalIdentifier(node.value)
        is IfExpression -> evalIfExpression(node)
        is IndexExpression -> evalIndexExpression(node)
        is InfixExpression -> evalInfixExpression(node)
        is IntegerLiteral -> MonkeyInteger(node.value)
        is LetStatement -> evalLetStatement(node)
        is PrefixExpression -> evalPrefixExpression(node)
        is Program -> evalProgram(node)
        is ReturnStatement -> evalReturnStatement(node)
        is StringLiteral -> MonkeyString(node.value)
        null -> MonkeyNull
    }

context(environment: Environment)
fun evalArrayLiteral(literal: ArrayLiteral): MonkeyObject {
    val elements = evalExpressions(literal.elements)

    if (elements.firstOrNull() is MonkeyError) {
        return elements.first()
    }

    return MonkeyArray(elements)
}

context(environment: Environment)
fun evalBlockStatement(statement: BlockStatement): MonkeyObject {
    var result: MonkeyObject = MonkeyNull

    statement.statements.forEach {
        result = eval(it)

        if (result is MonkeyReturn || result is MonkeyError) {
            return result
        }
    }

    return result
}

context(environment: Environment)
fun evalCallExpression(expression: CallExpression): MonkeyObject {
    val function = eval(expression.function)

    if (function is MonkeyError || function !is MonkeyCallable) {
        return function
    }

    val arguments = evalExpressions(expression.arguments)

    if (arguments.firstOrNull() is MonkeyError) {
        return arguments.first()
    }

    return when (function) {
        is MonkeyBuiltInFunction -> function.value(arguments)
        is MonkeyFunction -> {
            val result = context(function.environment.copy(function.function.parameters, arguments)) {
                eval(function.function.body)
            }

            if (result is MonkeyReturn) result.value else result
        }
    }
}

context(environment: Environment)
fun evalExpressions(expressions: Iterable<Expression>): List<MonkeyObject> =
    expressions.map {
        val argument = eval(it)

        if (argument is MonkeyError) {
            return listOf(argument)
        }

        argument
    }

context(environment: Environment)
fun evalHashLiteral(literal: HashLiteral): MonkeyObject {
    val map = literal.pairs.map { (keyExpression, valueExpression) ->
        val key = eval(keyExpression)

        if (key is MonkeyError) {
            return key
        }

        if (key !is MonkeyHashKey) {
            return MonkeyError("key type ${key.type} not suitable as a hash key")
        }

        val value = eval(valueExpression)

        if (value is MonkeyError) {
            return value
        }

        key to value
    }.toMap()

    return MonkeyHash(map)
}

context(environment: Environment)
fun evalIdentifier(name: String) =
    environment[name] ?: MonkeyError("identifier not found: $name")

@Suppress("IfThenToElvis")
context(environment: Environment)
fun evalIfExpression(expression: IfExpression): MonkeyObject {
    return eval(expression.condition).let {
        if (it is MonkeyError) {
            it
        } else if (isTruthy(it)) {
            eval(expression.consequence)
        } else if (expression.alternative != null) {
            eval(expression.alternative)
        } else {
            MonkeyNull
        }
    }
}

context(environment: Environment)
fun evalIndexExpression(expression: IndexExpression): MonkeyObject {
    val left = eval(expression.left)

    if (left is MonkeyError) {
        return left
    }

    val index = eval(expression.index)

    if (index is MonkeyError) {
        return index
    }

    return if (left is MonkeyArray && index is MonkeyInteger) {
        if (index.value < 0 || index.value >= left.elements.size) {
            MonkeyNull
        } else {
            left.elements[index.value]
        }
    } else if (left is MonkeyHash) {
        if (index is MonkeyHashKey) {
            left.value[index] ?: MonkeyNull
        } else {
            MonkeyError("unusable as hash key: ${index.type}")
        }
    } else {
        MonkeyError("index operator not supported on type ${left.type}")
    }
}

context(environment: Environment)
fun evalInfixExpression(expression: InfixExpression): MonkeyObject {
    val left = eval(expression.left)

    if (left is MonkeyError) {
        return left
    }

    val right = eval(expression.right)

    if (right is MonkeyError) {
        return right
    }

    @Suppress("CascadeIf")
    return if (left is MonkeyInteger && right is MonkeyInteger) {
        when (expression.operator) {
            InfixExpression.Operator.PLUS -> MonkeyInteger(left.value + right.value)
            InfixExpression.Operator.MINUS -> MonkeyInteger(left.value - right.value)
            InfixExpression.Operator.MULTIPLY -> MonkeyInteger(left.value * right.value)
            InfixExpression.Operator.DIVIDE -> MonkeyInteger(left.value / right.value)
            InfixExpression.Operator.LESS_THAN -> MonkeyBoolean(left.value < right.value)
            InfixExpression.Operator.GREATER_THAN -> MonkeyBoolean(left.value > right.value)
            InfixExpression.Operator.EQUALS -> MonkeyBoolean(left.value == right.value)
            InfixExpression.Operator.NOT_EQUALS -> MonkeyBoolean(left.value != right.value)
        }
    } else if (left is MonkeyBoolean && right is MonkeyBoolean) {
        when (expression.operator) {
            InfixExpression.Operator.EQUALS -> MonkeyBoolean(left.value == right.value)
            InfixExpression.Operator.NOT_EQUALS -> MonkeyBoolean(left.value != right.value)
            else -> MonkeyError("unknown operator: BOOLEAN ${expression.operator} BOOLEAN")
        }
    } else if (left is MonkeyString && right is MonkeyString) {
        when (expression.operator) {
            InfixExpression.Operator.PLUS -> MonkeyString(left.value + right.value)
            InfixExpression.Operator.EQUALS -> MonkeyBoolean(left.value == right.value)
            InfixExpression.Operator.NOT_EQUALS -> MonkeyBoolean(left.value != right.value)
            else -> MonkeyError("unknown operator: STRING ${expression.operator} STRING")
        }
    } else {
        MonkeyError("type mismatch: ${left.type} ${expression.operator} ${right.type}")
    }
}

context(environment: Environment)
fun evalLetStatement(statement: LetStatement): MonkeyObject {
    val result = eval(statement.value)

    if (result !is MonkeyError) {
        environment[statement.name.value] = result
    }

    return result
}

fun evalPrefixBang(value: MonkeyObject) =
    when (value) {
        MonkeyBoolean.False -> MonkeyBoolean.True
        MonkeyBoolean.True -> MonkeyBoolean.False
        MonkeyNull -> MonkeyBoolean.True
        else -> MonkeyBoolean.False
    }

context(environment: Environment)
fun evalPrefixExpression(expression: PrefixExpression): MonkeyObject {
    val right = eval(expression.right)

    if (right is MonkeyError) {
        return right
    }

    return when (expression.operator) {
        PrefixExpression.Operator.`!` -> evalPrefixBang(right)
        PrefixExpression.Operator.`-` -> evalPrefixMinus(right)
    }
}

fun evalPrefixMinus(value: MonkeyObject) =
    if (value is MonkeyInteger) {
        MonkeyInteger(-value.value)
    } else {
        MonkeyError("unknown operator: -${value.type}")
    }

context(environment: Environment)
fun evalProgram(program: Program): MonkeyObject {
    var result: MonkeyObject = MonkeyNull

    program.statements.forEach {
        result = eval(it)

        if (result is MonkeyReturn) {
            return result.value
        } else if (result is MonkeyError) {
            return result
        }
    }

    return result
}

context(environment: Environment)
fun evalReturnStatement(statement: ReturnStatement): MonkeyObject {
    val result = eval(statement.value)

    return if (result is MonkeyError) {
        result
    } else {
        MonkeyReturn(result)
    }
}

fun isTruthy(value: MonkeyObject) =
    when (value) {
        MonkeyNull -> false
        MonkeyBoolean.False -> false
        else -> true
    }
