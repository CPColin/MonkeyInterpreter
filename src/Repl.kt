fun main() {
    val environment = Environment()

    println("Welcome to the Monkey REPL!")

    while (true) {
        print(">> ")

        val line = readlnOrNull() ?: break

        val lexer = Lexer(line)
        val parser = Parser(lexer)
        val program = parser.parseProgram()

        if (parser.errors.isNotEmpty()) {
            parser.errors.forEach {
                println("\t$it")
            }

            continue
        } else {
            context(environment) {
                val result = eval(program)

                println(result.string)
            }
        }
    }
}
