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
