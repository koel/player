package phanan.koel.shared.stores

import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class VaultTest {
    private data class Item(val id: String, val label: String)

    private val vault = Vault<Item> { it.id }

    @Test
    fun syncReplacesKnownEntitiesAndDropsDuplicates() {
        vault.sync(listOf(Item("1", "old")))

        val synced = vault.sync(listOf(Item("1", "new"), Item("2", "two"), Item("1", "new")))

        assertEquals(listOf(Item("1", "new"), Item("2", "two")), synced)
        assertEquals("new", vault["1"]?.label)
    }

    @Test
    fun liveListsFollowUpdatesImmediatelyAndKeepTheirOrder() {
        vault.sync(listOf(Item("1", "one"), Item("2", "two")))
        val live = vault.liveList().apply { ids = listOf("2", "1", "missing") }

        vault.update("1") { it.copy(label = "ONE") }
        assertEquals(listOf(Item("2", "two"), Item("1", "ONE")), live.items.value)

        live.append(listOf("1", "3"))
        vault.sync(Item("3", "three"))
        assertEquals(listOf("two", "ONE", "three"), live.items.value.map { it.label })

        live.prepend("3")
        live.remove("2")
        assertEquals(listOf("three", "ONE"), live.items.value.map { it.label })
    }

    @Test
    fun liveSnapshotsResolveAgainstTheLatestEntities() = runTest {
        vault.sync(listOf(Item("1", "one")))
        val live = vault.live(listOf("1"))

        vault.update("1") { it.copy(label = "changed") }

        assertEquals(listOf(Item("1", "changed")), live.first())
    }
}
