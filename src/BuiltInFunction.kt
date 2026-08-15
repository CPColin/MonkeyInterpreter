typealias BuiltInFunction = (List<MonkeyObject>) -> MonkeyObject

val BUILT_IN_FUNCTIONS: Map<String, MonkeyBuiltInFunction> = mapOf(
    "len" to MonkeyBuiltInFunction { args ->
        if (args.size != 1) {
            MonkeyError("wrong number of arguments. got 2, but wanted 1")
        } else if (args[0] is MonkeyString) {
            MonkeyInteger(args[0].string.length)
        } else {
            MonkeyError("argument to `len` not supported, got INTEGER")
        }
    }
)
