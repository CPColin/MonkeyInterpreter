import ceylon.collection {
    ArrayList
}

import ceylon.language.meta {
    type
}

shared MonkeyObject eval(Node? node, Environment environment) {
    switch (node)
    case (is ArrayLiteral) {
        value elements = evalExpressions(node.elements else empty, environment);
        
        if (is MonkeyError elements) {
            return elements;
        }
        
        return MonkeyArray(elements);
    }
    case (is BlockStatement|Program) {
        return evalBlock(node, environment);
    }
    case (is BooleanLiteral) {
        return monkeyBoolean(node.val);
    }
    case (is CallExpression) {
        value result = eval(node.func, environment);
        
        if (is MonkeyError result) {
            return result;
        }
        
        value arguments = evalExpressions(node.arguments else empty, environment);
        
        if (is MonkeyError arguments) {
            return arguments;
        }
        
        return applyFunction(result, arguments);
    }
    case (is ExpressionStatement) {
        return eval(node.expression, environment);
    }
    case (is FunctionLiteral) {
        return MonkeyFunction(node.parameters, node.body, environment);
    }
    case (is Identifier) {
        return evalIdentifier(node, environment);
    }
    case (is IfExpression) {
        return evalIfExpression(node, environment);
    }
    case (is InfixExpression) {
        value left = eval(node.left, environment);
        
        if (is MonkeyError left) {
            return left;
        }
        
        value right = eval(node.right, environment);
        
        if (is MonkeyError right) {
            return right;
        }
        
        return evalInfixExpression(node.operator, left, right);
    }
    case (is IntegerLiteral) {
        return MonkeyInteger(node.val);
    }
    case (is LetStatement) {
        value val = eval(node.val, environment);
        
        if (is MonkeyError val) {
            return val;
        }
        
        environment[node.name.val] = val;
        
        return val;
    }
    case (is PrefixExpression) {
        value right = eval(node.right, environment);
        
        return if (is MonkeyError right) then right else evalPrefixExpression(node.operator, right);
    }
    case (is ReturnStatement) {
        value val = eval(node.returnValue, environment);
        
        return if (is MonkeyError val) then val else MonkeyReturnValue(val);
    }
    case (is StringLiteral) {
        return MonkeyString(node.val);
    }
    else {
        return monkeyNull;
    }
}

MonkeyObject applyFunction(MonkeyObject func, MonkeyObject[] arguments) {
    if (is MonkeyFunction func) {
        value environment = extendFunctionEnvironment(func, arguments);
        value result = eval(func.body, environment);
        
        return if (is MonkeyReturnValue result) then (result.val else monkeyNull) else result;
    }
    else if (is MonkeyBuiltIn func) {
        return func.func(arguments);
    }
    else {
        return MonkeyError.notAFunction(func);
    }
}

MonkeyObject evalBangOperatorExpression(MonkeyObject right)
        => monkeyBoolean(!isTruthy(right));

MonkeyObject evalBlock(BlockStatement|Program block, Environment environment) {
    variable MonkeyObject result = monkeyNull;
    
    for (statement in block.statements) {
        result = eval(statement, environment);
        
        if (is MonkeyReturnValue returnValue = result) {
            return if (is Program block) then (returnValue.val else monkeyNull) else returnValue;
        }
        else if (is MonkeyError error = result) {
            return error;
        }
    }
    
    return result;
}

MonkeyError|MonkeyObject[] evalExpressions(Expression[] expressions, Environment environment) {
    value results = ArrayList<MonkeyObject>();
    
    for (expression in expressions) {
        value result = eval(expression, environment);
        
        if (is MonkeyError result) {
            return result;
        }
        
        results.add(result);
    }
    
    return results.sequence();
}

MonkeyObject evalIdentifier(Identifier identifier, Environment environment) {
    value name = identifier.val;
    
    if (exists val = environment[name]) {
        return val;
    }
    else if (exists builtInFunction = builtInFunctions[name]) {
        return MonkeyBuiltIn(builtInFunction);
    }
    else {
        return MonkeyError.identifierNotFound(name);
    }
}

MonkeyObject evalIfExpression(IfExpression expression, Environment environment) {
    value condition = eval(expression.condition, environment);
    
    if (is MonkeyError condition) {
        return condition;
    }
    else if (isTruthy(condition)) {
        return eval(expression.consequence, environment);
    }
    else if (exists alternative = expression.alternative) {
        return eval(alternative, environment);
    }
    else {
        return monkeyNull;
    }
}

MonkeyObject evalInfixExpression(String operator, MonkeyObject left, MonkeyObject right) {
    if (is MonkeyInteger left, is MonkeyInteger right) {
        return evalInfixIntegerExpression(operator, left, right);
    }
    else if (is MonkeyBoolean left, is MonkeyBoolean right) {
        return evalInfixBooleanExpression(operator, left, right);
    }
    else if (is MonkeyString left, is MonkeyString right) {
        return evalInfixStringExpression(operator, left, right);
    }
    
    return MonkeyError.infixTypesNotSupported(type(left), operator, type(right));
}

MonkeyObject evalInfixBooleanExpression(String operator, MonkeyBoolean left, MonkeyBoolean right) {
    if (operator == "==") {
        return monkeyBoolean(left == right);
    }
    else if (operator == "!=") {
        return monkeyBoolean(left != right);
    }
    else {
        return MonkeyError.infixOperatorNotSupported(operator, `MonkeyBoolean`);
    }
}

MonkeyObject evalInfixIntegerExpression(String operator, MonkeyInteger left, MonkeyInteger right) {
    value leftValue = left.val;
    value rightValue = right.val;
    
    switch (operator)
    case ("+") {
        return MonkeyInteger(leftValue + rightValue);
    }
    case ("-") {
        return MonkeyInteger(leftValue - rightValue);
    }
    case ("*") {
        return MonkeyInteger(leftValue * rightValue);
    }
    case ("/") {
        return MonkeyInteger(leftValue / rightValue);
    }
    case ("<") {
        return monkeyBoolean(leftValue < rightValue);
    }
    case (">") {
        return monkeyBoolean(leftValue > rightValue);
    }
    case ("==") {
        return monkeyBoolean(leftValue == rightValue);
    }
    case ("!=") {
        return monkeyBoolean(leftValue != rightValue);
    }
    else {
        return MonkeyError.infixOperatorNotSupported(operator, `MonkeyInteger`);
    }
}

MonkeyObject evalInfixStringExpression(String operator, MonkeyString left, MonkeyString right) {
    if (operator == "+") {
        return MonkeyString(left.val + right.val);
    }
    else {
        return MonkeyError.infixOperatorNotSupported(operator, `MonkeyString`);
    }
}

MonkeyObject evalMinusPrefixOperatorExpression(MonkeyObject right) {
    if (!is MonkeyInteger right) {
        return MonkeyError.prefixTypeNotSupported("-", type(right));
    }
    
    return MonkeyInteger(-right.val);
}

MonkeyObject evalPrefixExpression(String operator, MonkeyObject right) {
    switch (operator)
    case ("!") {
        return evalBangOperatorExpression(right);
    }
    case ("-") {
        return evalMinusPrefixOperatorExpression(right);
    }
    else {
        return MonkeyError.prefixOperatorNotSupported(operator);
    }
}

Environment extendFunctionEnvironment(MonkeyFunction func, MonkeyObject[] arguments) {
    value environment = Environment.enclosedBy(func.environment);
    
    for (index in 0:func.parameters.size) {
        value parameter = func.parameters[index];
        value val = arguments[index] else monkeyNull;
        
        assert (exists parameter);
        
        environment[parameter.val] = val;
    }
    
    return environment;
}

Boolean isTruthy(MonkeyObject val) {
    switch (val)
    case (monkeyTrue) {
        return true;
    }
    case (monkeyFalse) {
        return false;
    }
    case (monkeyNull) {
        return false;
    }
    else {
        return true;
    }
}
