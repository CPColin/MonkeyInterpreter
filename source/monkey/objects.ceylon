import ceylon.language.meta.model {
    Type
}

alias ObjectType => String;

// TODO: The Go code uses all these types. This code may not need them.

shared interface MonkeyObject {
    //shared formal ObjectType type;
    
    shared actual formal String string;
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

shared class MonkeyError satisfies MonkeyObject {
    String message;
    
    shared new infixOperatorNotSupported(String operator, Type<> type) {
        message = "Infix operator ``operator`` is not defined for type ``type``";
    }
    
    shared new infixTypesNotSupported(Type<> leftType, String operator, Type<> rightType) {
        message = "Infix operator ``operator`` does not support ``leftType`` and ``rightType``";
    }
    
    shared new prefixOperatorNotSupported(String operator) {
        message = "Prefix operator ``operator`` is not defined";
    }
    
    shared new prefixTypeNotSupported(String operator, Type<> type) {
        message = "Prefix operator ``operator`` does not support ``type``";
    }
    
    string = message;
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
