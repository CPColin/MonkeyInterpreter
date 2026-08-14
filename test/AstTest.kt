import kotlin.test.Test
import kotlin.test.assertEquals

class AstTest {
    @Test
    fun string() {
        val program = Program(
            listOf(
                LetStatement(Identifier("myVar"), Identifier("anotherVar"))
            )
        )

        assertEquals("let myVar = anotherVar;", program.string)
    }
}
