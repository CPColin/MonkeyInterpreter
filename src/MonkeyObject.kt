sealed interface MonkeyObject {
    val string: String

    val type: String
}

data class MonkeyArray(val elements: List<MonkeyObject>) : MonkeyObject {
    override val string = elements.joinToString(prefix = "[", separator = ", ", postfix = "]") { it.string }
    override val type = "ARRAY"
}

@JvmInline
value class MonkeyBoolean private constructor(val value: Boolean) : MonkeyObject {
    override val string get() = value.toString()

    override val type get() = "BOOLEAN"

    companion object {
        val False = MonkeyBoolean(false)
        val True = MonkeyBoolean(true)

        operator fun invoke(value: Boolean) = if (value) True else False
    }
}

@JvmInline
value class MonkeyBuiltInFunction(val value: BuiltInFunction) : MonkeyCallable {
    override val string get() = value.toString()

    override val type get() = "BUILTIN"
}

sealed interface MonkeyCallable : MonkeyObject

@JvmInline
value class MonkeyError(val message: String) : MonkeyObject {
    override val string get() = "ERROR: $message"
    override val type get() = "ERROR"
}

data class MonkeyFunction(val function: FunctionLiteral, val environment: Environment) : MonkeyCallable {
    override val string = function.string
    override val type = "FUNCTION"
}

@JvmInline
value class MonkeyInteger(val value: Int) : MonkeyObject {
    override val string get() = value.toString()
    override val type get() = "INTEGER"
}

object MonkeyNull : MonkeyObject {
    override val string = "null"
    override val type get() = "NULL"
}

@JvmInline
value class MonkeyReturn(val value: MonkeyObject) : MonkeyObject by value

@JvmInline
value class MonkeyString(val value: String) : MonkeyObject {
    override val string get() = value
    override val type get() = "STRING"
}
