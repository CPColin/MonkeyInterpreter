import ceylon.collection {
    HashMap
}

shared class Environment
        satisfies Correspondence<String, MonkeyObject>
            & KeyedCorrespondenceMutator<String, MonkeyObject> {
    value environment = HashMap<String, MonkeyObject>();
    
    Environment? outerEnvironment;
    
    shared new() {
        outerEnvironment = null;
    }
    
    shared new enclosedBy(Environment outerEnvironment) {
        this.outerEnvironment = outerEnvironment;
    }
    
    defines(String name)
            => environment.defines(name)
                || (if (exists outerEnvironment)
                    then outerEnvironment.defines(name)
                    else false);
    
    get(String name)
            => environment[name]
                else (if (exists outerEnvironment)
                    then outerEnvironment[name]
                    else null);
    
    put(String name, MonkeyObject val) => environment[name] = val;
}
