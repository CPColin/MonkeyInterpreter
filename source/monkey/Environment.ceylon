import ceylon.collection {
    HashMap
}

shared class Environment()
        satisfies Correspondence<String, MonkeyObject>
            & KeyedCorrespondenceMutator<String, MonkeyObject> {
    value environment = HashMap<String, MonkeyObject>();
    
    defines(String name) => environment.defines(name);
    
    get(String name) => environment[name];
    
    put(String name, MonkeyObject val) => environment[name] = val;
}
