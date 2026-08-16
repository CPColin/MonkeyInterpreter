typealias BuiltInFunction = (List<MonkeyObject>) -> MonkeyObject

private fun expectArgumentCount(args: List<MonkeyObject>, expected: Int) =
    if (args.size != expected) {
        MonkeyError("wrong number of arguments. got ${args.size}, but wanted $expected")
    } else {
        null
    }

private fun <T : MonkeyObject> expectArgumentType(args: List<MonkeyObject>, index: Int, expected: T) =
    args[index].let {
        if (expected::class.isInstance(it)) {
            it
        } else {
            MonkeyError("wrong argument type. got ${it.type}, but wanted ${expected.type}")
        }
    }

val BUILT_IN_FUNCTIONS: Map<String, MonkeyBuiltInFunction> = mapOf(
    "first" to MonkeyBuiltInFunction { args ->
        expectArgumentCount(args, 1)?.run { return@MonkeyBuiltInFunction this }

        val array = expectArgumentType(args, 0, MonkeyArray(emptyList()))

        return@MonkeyBuiltInFunction if (array is MonkeyArray) {
            array.elements.firstOrNull() ?: MonkeyNull
        } else {
            array
        }
    },
    "last" to MonkeyBuiltInFunction { args ->
        expectArgumentCount(args, 1)?.run { return@MonkeyBuiltInFunction this }

        val array = expectArgumentType(args, 0, MonkeyArray(emptyList()))

        return@MonkeyBuiltInFunction if (array is MonkeyArray) {
            array.elements.lastOrNull() ?: MonkeyNull
        } else {
            array
        }
    },
    "len" to MonkeyBuiltInFunction { args ->
        expectArgumentCount(args, 1)?.run { return@MonkeyBuiltInFunction this }

        return@MonkeyBuiltInFunction when (val value = args[0]) {
            is MonkeyString -> MonkeyInteger(value.value.length)
            is MonkeyArray -> MonkeyInteger(value.elements.size)
            else -> MonkeyError("argument to `len` not supported, got ${value.type}")
        }
    },
    "push" to MonkeyBuiltInFunction { args ->
        expectArgumentCount(args, 2)?.run { return@MonkeyBuiltInFunction this }

        val array = expectArgumentType(args, 0, MonkeyArray(emptyList()))
        val value = args[1]

        return@MonkeyBuiltInFunction if (array is MonkeyArray) {
            MonkeyArray(array.elements + value)
        } else {
            array
        }
    },
    "puts" to MonkeyBuiltInFunction { args ->
        args.forEach { println(it.string) }

        MonkeyNull
    },
    "rest" to MonkeyBuiltInFunction { args ->
        expectArgumentCount(args, 1)?.run { return@MonkeyBuiltInFunction this }

        val array = expectArgumentType(args, 0, MonkeyArray(emptyList()))

        return@MonkeyBuiltInFunction if (array is MonkeyArray) {
            MonkeyArray(array.elements.drop(1))
        } else {
            array
        }
    }
)
