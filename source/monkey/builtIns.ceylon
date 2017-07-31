import ceylon.language.meta {
    type
}

shared alias BuiltInFunction => MonkeyObject(MonkeyObject[]);

MonkeyError? checkArgumentCount(MonkeyObject[] arguments, Integer expectedCount)
        => if (arguments.size == expectedCount)
            then null
            else MonkeyError.argumentCountMismatch(arguments.size, expectedCount);

Type|MonkeyError checkArgumentType<Type>(MonkeyObject[] arguments, Integer index) {
    value argument = arguments[index];
    
    assert (exists argument);
    
    if (is Type argument) {
        return argument;
    }
    else {
        return MonkeyError.argumentTypeMismatch(index, type(argument), `Type`);
    }
}

Map<String, BuiltInFunction> builtInFunctions = map {
    "len" -> ((MonkeyObject[] arguments) {
        if (exists error = checkArgumentCount(arguments, 1)) {
            return error;
        }
        
        value val = checkArgumentType<MonkeyString>(arguments, 0);
        
        if (is MonkeyError val) {
            return val;
        }
        
        return MonkeyInteger(val.val.size);
    })
};
