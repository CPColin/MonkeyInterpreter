shared void run() {
    print("Welcome to the Monkey REPL!");
    
    while (true) {
        process.write(">> ");
        
        value line = process.readLine();
        
        if (!exists line) {
            break;
        }
        
        value lexer = Lexer(line);
        
        while (true) {
            value token = lexer.nextToken();
            
            if (token.type == TokenType.eof) {
                break;
            }
            
            print(token);
        }
    }
}
