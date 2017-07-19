shared MonkeyObject? eval(Node? node) {
    switch (node)
    case (is BooleanLiteral) {
        return monkeyBoolean(node.val);
    }
    case (is ExpressionStatement) {
        return eval(node.expression);
    }
    case (is InfixExpression) {
        value left = eval(node.left);
        value right = eval(node.right);
        
        return evalInfixExpression(node.operator, left, right);
    }
    case (is IntegerLiteral) {
        return MonkeyInteger(node.val);
    }
    case (is PrefixExpression) {
        value right = eval(node.right);
        
        return evalPrefixExpression(node.operator, right);
    }
    case (is Program) {
        return evalStatements(node.statements);
    }
    else {
        return null;
    }
}

MonkeyObject? evalBangOperatorExpression(MonkeyObject? right) {
    switch (right)
    case (monkeyTrue) {
        return monkeyFalse;
    }
    case (monkeyFalse) {
        return monkeyTrue;
    }
    case (monkeyNull) {
        return monkeyTrue;
    }
    else {
        return monkeyFalse;
    }
}

MonkeyObject? evalInfixExpression(String operator, MonkeyObject? left, MonkeyObject? right) {
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
    }
    
    return null;
}

MonkeyObject? evalIntegerInfixExpression(String operator, MonkeyInteger left, MonkeyInteger right) {
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
        return null;
    }
}

MonkeyObject? evalMinusPrefixOperatorExpression(MonkeyObject? right) {
    if (!is MonkeyInteger right) {
        return null;
    }
    
    return MonkeyInteger(-right.val);
}

MonkeyObject? evalPrefixExpression(String operator, MonkeyObject? right) {
    switch (operator)
    case ("!") {
        return evalBangOperatorExpression(right);
    }
    case ("-") {
        return evalMinusPrefixOperatorExpression(right);
    }
    else {
        return null;
    }
}

MonkeyObject? evalStatements(Statement[] statements) {
    variable MonkeyObject? result = null;
    
    for (statement in statements) {
        result = eval(statement);
    }
    
    return result;
}
