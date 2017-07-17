shared abstract class TokenType
        of illegal | eof
        | ident | int
        | \iassign | plus | minus | bang | asterisk | slash | lt | gt | eq | notEq
        | comma | semicolon | lparen | rparen | lbrace | rbrace
        | \ifunction | \ilet | \itrue | \ifalse | \iif | \ielse | \ireturn {
    shared static object illegal extends TokenType("ILLEGAL") {}
    shared static object eof extends TokenType("EOF") {}
    
    // Identifiers and literals
    shared static object ident extends TokenType("IDENT") {}
    shared static object int extends TokenType("INT") {}
    
    // Operators
    shared static object \iassign extends TokenType("=") {}
    shared static object plus extends TokenType("+") {}
    shared static object minus extends TokenType("-") {}
    shared static object bang extends TokenType("!") {}
    shared static object asterisk extends TokenType("*") {}
    shared static object slash extends TokenType("/") {}
    
    shared static object lt extends TokenType("<") {}
    shared static object gt extends TokenType(">") {}
    
    shared static object eq extends TokenType("==") {}
    shared static object notEq extends TokenType("!=") {}
    
    // Delimiters
    shared static object comma extends TokenType(",") {}
    shared static object semicolon extends TokenType(";") {}
    
    shared static object lparen extends TokenType("(") {}
    shared static object rparen extends TokenType(")") {}
    shared static object lbrace extends TokenType("{") {}
    shared static object rbrace extends TokenType("}") {}
    
    // Keywords
    shared static object \ifunction extends TokenType("FUNCTION") {}
    shared static object \ilet extends TokenType("LET") {}
    shared static object \itrue extends TokenType("TRUE") {}
    shared static object \ifalse extends TokenType("FALSE") {}
    shared static object \iif extends TokenType("IF") {}
    shared static object \ielse extends TokenType("ELSE") {}
    shared static object \ireturn extends TokenType("RETURN") {}
    
    String humanReadable;
    
    shared new(String humanReadable) {
        this.humanReadable = humanReadable;
    }
    
    string => humanReadable;
}

shared class Token(type, literal) {
    shared TokenType type;
    
    shared String literal;
    
    string => "[ ``type``, ``literal`` ]";
}

Map<String, TokenType> keywords = map {
    "fn" -> TokenType.\ifunction,
    "let" -> TokenType.\ilet,
    "true" -> TokenType.\itrue,
    "false" -> TokenType.\ifalse,
    "if" -> TokenType.\iif,
    "else" -> TokenType.\ielse,
    "return" -> TokenType.\ireturn
};

TokenType identifier(String literal) => keywords[literal] else TokenType.ident;
