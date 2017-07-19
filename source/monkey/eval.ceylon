shared MonkeyObject? eval(Node? node) {
    switch (node)
    case (is Program) {
        return evalStatements(node.statements);
    }
    case (is ExpressionStatement) {
        return eval(node.expression);
    }
    case (is BooleanLiteral) {
        return monkeyBoolean(node.val);
    }
    case (is IntegerLiteral) {
        return MonkeyInteger(node.val);
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
