shared void run() {
    print("Welcome to the Monkey REPL!");
    
    value environment = Environment();
    
    while (true) {
        process.write(">> ");
        
        value line = process.readLine();
        
        if (!exists line) {
            break;
        }
        
        value lexer = Lexer(line);
        value parser = Parser(lexer);
        value program = parser.parseProgram();
        value errors = parser.errors;
        
        if (nonempty errors) {
            errors.each(print);
        }
        else {
            value result = eval(program, environment);
            
            print(result);
        }
    }
}
