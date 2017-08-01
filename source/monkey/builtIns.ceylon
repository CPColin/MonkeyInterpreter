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
    "first" -> ((MonkeyObject[] arguments) {
        if (exists error = checkArgumentCount(arguments, 1)) {
            return error;
        }
        
        switch (val = checkArgumentType<MonkeyArray>(arguments, 0))
        case (is MonkeyArray) {
            return if (exists first = val.elements.first) then first else monkeyNull;
        }
        case (is MonkeyError) {
            return val;
        }
    }),
    "last" -> ((MonkeyObject[] arguments) {
        if (exists error = checkArgumentCount(arguments, 1)) {
            return error;
        }
        
        switch (val = checkArgumentType<MonkeyArray>(arguments, 0))
        case (is MonkeyArray) {
            return if (exists last = val.elements.last) then last else monkeyNull;
        }
        case (is MonkeyError) {
            return val;
        }
    }),
    "len" -> ((MonkeyObject[] arguments) {
        if (exists error = checkArgumentCount(arguments, 1)) {
            return error;
        }
        
        switch (val = checkArgumentType<MonkeyArray|MonkeyString>(arguments, 0))
        case (is MonkeyArray) {
            return MonkeyInteger(val.elements.size);
        }
        case (is MonkeyString) {
            return MonkeyInteger(val.val.size);
        }
        case (is MonkeyError) {
            return val;
        }
    }),
    "push" -> ((MonkeyObject[] arguments) {
        if (exists error = checkArgumentCount(arguments, 2)) {
            return error;
        }
        
        value array = checkArgumentType<MonkeyArray>(arguments, 0);
        
        if (is MonkeyError array) {
            return array;
        }
        
        value element = checkArgumentType<MonkeyObject>(arguments, 1);
        
        return MonkeyArray(array.elements.withTrailing(element));
    }),
    "rest" -> ((MonkeyObject[] arguments) {
        if (exists error = checkArgumentCount(arguments, 1)) {
            return error;
        }
        
        switch (val = checkArgumentType<MonkeyArray>(arguments, 0))
        case (is MonkeyArray) {
            value elements = val.elements;
            
            return elements.empty then monkeyNull else MonkeyArray(elements.rest);
        }
        case (is MonkeyError) {
            return val;
        }
    })
};
