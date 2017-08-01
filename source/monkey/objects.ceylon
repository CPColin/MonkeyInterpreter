import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type
}

alias ObjectType => String;

shared interface MonkeyObject {
    shared actual formal String string;
}

shared class MonkeyArray(elements) satisfies MonkeyObject {
    shared MonkeyObject[] elements;
    
    string = "[``StringBuilder().appendAll(elements.map(MonkeyObject.string).interpose(", ")).string``]";
}

shared abstract class MonkeyBoolean(val)
        of monkeyTrue | monkeyFalse
        satisfies MonkeyObject {
    shared Boolean val;
    
    string = val.string;
}

shared object monkeyTrue extends MonkeyBoolean(true) {}
shared object monkeyFalse extends MonkeyBoolean(false) {}
shared MonkeyBoolean monkeyBoolean(Boolean val)
    => val then monkeyTrue else monkeyFalse;

shared class MonkeyBuiltIn(func) satisfies MonkeyObject {
    shared BuiltInFunction func;
    
    string = "built-in function";
}

shared class MonkeyError satisfies MonkeyObject {
    String message;
    
    shared new argumentCountMismatch(Integer actual, Integer expected) {
        message = "Incorrect number of arguments. Found ``actual`` but expected ``expected``.";
    }
    
    shared new argumentTypeMismatch(Integer index, Type<> actual, Type<> expected) {
        message = "Incorrect type for argument ``index``. Found ``actual`` but expected ``expected``.";
    }
    
    shared new identifierNotFound(String identifier) {
        message = "Identifier '``identifier``' not found";
    }
    
    shared new infixOperatorNotSupported(String operator, Type<> type) {
        message = "Infix operator ``operator`` is not defined for type ``type``";
    }
    
    shared new infixTypesNotSupported(Type<> leftType, String operator, Type<> rightType) {
        message = "Infix operator ``operator`` does not support ``leftType`` and ``rightType``";
    }
    
    shared new notAFunction(MonkeyObject func) {
        message = "Not a function: ``type(func)``";
    }
    
    shared new prefixOperatorNotSupported(String operator) {
        message = "Prefix operator ``operator`` is not defined";
    }
    
    shared new prefixTypeNotSupported(String operator, Type<> type) {
        message = "Prefix operator ``operator`` does not support ``type``";
    }
    
    string = message;
}

shared class MonkeyFunction(parameters, body, environment) satisfies MonkeyObject {
    shared Identifier[] parameters;
    
    shared BlockStatement body;
    
    shared Environment environment;
    
    string = "fn(``StringBuilder().appendAll(parameters.map(Identifier.val).interpose(", ")).string``) ``body``";
}

shared class MonkeyInteger(val) satisfies MonkeyObject {
    shared Integer val;
    
    string = val.string;
}

shared abstract class MonkeyNull()
        of monkeyNull
        satisfies MonkeyObject {
    string = "null";
}

shared object monkeyNull extends MonkeyNull() {}

shared class MonkeyReturnValue(val) satisfies MonkeyObject {
    shared MonkeyObject? val;
    
    string = val?.string else "";
}

shared class MonkeyString(val) satisfies MonkeyObject {
    shared String val;
    
    string = val;
}
