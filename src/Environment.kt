class Environment(private val map: MutableMap<String, MonkeyObject> = mutableMapOf()) :
    MutableMap<String, MonkeyObject> by map {
    fun copy(parameters: List<Identifier>, arguments: List<MonkeyObject>): Environment {
        val environment = Environment(map.toMutableMap())

        parameters.forEachIndexed { index, parameter -> environment[parameter.value] = arguments[index] }

        return environment
    }
}
