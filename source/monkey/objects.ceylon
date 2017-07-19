alias ObjectType => String;

// TODO: The Go code uses all these types. This code may not need them.

shared interface MonkeyObject {
    //shared formal ObjectType type;
    
    shared actual formal String string;
}

shared class MonkeyInteger(val) satisfies MonkeyObject {
    shared Integer val;
    
    string = val.string;
}

shared class MonkeyBoolean(val) satisfies MonkeyObject {
    shared Boolean val;
    
    string = val.string;
}

shared class MonkeyNull() satisfies MonkeyObject {
    string = "null";
}
