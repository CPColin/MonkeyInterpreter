@file:Suppress("IfThenToElvis")

context(environment: Environment)
fun eval(node: Node?): MonkeyObject =
    when (node) {
        is BlockStatement -> evalBlockStatement(node)
        is BooleanLiteral -> MonkeyBoolean(node.value)
        is CallExpression -> evalCallExpression(node)
        is ExpressionStatement -> eval(node.value)
        is FunctionLiteral -> MonkeyFunction(node, environment)
        is Identifier -> evalIdentifier(node.value)
        is IfExpression -> evalIfExpression(node)
        is InfixExpression -> evalInfixExpression(node)
        is IntegerLiteral -> MonkeyInteger(node.value)
        is LetStatement -> evalLetStatement(node)
        is PrefixExpression -> evalPrefixExpression(node)
        is Program -> evalProgram(node)
        is ReturnStatement -> evalReturnStatement(node)
        is StringLiteral -> MonkeyString(node.value)
        null -> MonkeyNull
        else -> error("Unsupported node type: ${node::class.simpleName}")
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

    if (function is MonkeyError || function !is MonkeyFunction) {
        return function
    }

    val arguments = expression.arguments.map {
        val argument = eval(it)

        if (argument is MonkeyError) {
            return argument
        }

        argument
    }

    val result = context(function.environment.copy(function.function.parameters, arguments)) {
        eval(function.function.body)
    }

    return if (result is MonkeyReturn) result.value else result
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
            "+" -> MonkeyInteger(left.value + right.value)
            "-" -> MonkeyInteger(left.value - right.value)
            "*" -> MonkeyInteger(left.value * right.value)
            "/" -> MonkeyInteger(left.value / right.value)
            "<" -> MonkeyBoolean(left.value < right.value)
            ">" -> MonkeyBoolean(left.value > right.value)
            "==" -> MonkeyBoolean(left.value == right.value)
            "!=" -> MonkeyBoolean(left.value != right.value)
            else -> MonkeyNull
        }
    } else if (left is MonkeyBoolean && right is MonkeyBoolean) {
        when (expression.operator) {
            "==" -> MonkeyBoolean(left.value == right.value)
            "!=" -> MonkeyBoolean(left.value != right.value)
            else -> MonkeyError("unknown operator: BOOLEAN ${expression.operator} BOOLEAN")
        }
    } else if (left is MonkeyString && right is MonkeyString) {
        when (expression.operator) {
            "+" -> MonkeyString(left.value + right.value)
            "==" -> MonkeyBoolean(left.value == right.value)
            "!=" -> MonkeyBoolean(left.value != right.value)
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
        "!" -> evalPrefixBang(right)
        "-" -> evalPrefixMinus(right)
        else -> error("Unsupported prefix operator: ${expression.operator}")
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
