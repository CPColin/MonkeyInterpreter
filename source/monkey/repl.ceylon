shared void run() {
    print("Welcome to the Monkey REPL!");
    
    while (true) {
        print(">> ");
        
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
            if (exists result = eval(program)) {
                print(result);
            }
        }
    }
}
