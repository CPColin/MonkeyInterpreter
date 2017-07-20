import ceylon.language.meta {
    type
}

shared MonkeyObject eval(Node? node, Environment environment) {
    switch (node)
    case (is BlockStatement|Program) {
        return evalBlock(node, environment);
    }
    case (is BooleanLiteral) {
        return monkeyBoolean(node.val);
    }
    case (is ExpressionStatement) {
        return eval(node.expression, environment);
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
    else {
        return monkeyNull;
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

MonkeyObject evalIdentifier(Identifier identifier, Environment environment) {
    value name = identifier.val;
    value val = environment[name];
    
    if (!exists val) {
        return MonkeyError.identifierNotFound(name);
    }
    
    return val;
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
        return evalIntegerInfixExpression(operator, left, right);
    }
    else if (is MonkeyBoolean left, is MonkeyBoolean right) {
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
    
    return MonkeyError.infixTypesNotSupported(type(left), operator, type(right));
}

MonkeyObject evalIntegerInfixExpression(String operator, MonkeyInteger left, MonkeyInteger right) {
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
