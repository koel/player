package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.PlaylistFolder
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlaylistFolderStoreTest {
    private val h = Harness()
    private val store = PlaylistFolderStore(h.api)

    private fun seed(vararg folders: JsonObject): List<PlaylistFolder> =
        folders.map { KoelJson.decodeFromJsonElement(PlaylistFolder.serializer(), it) }.also(store::seed)

    @Test
    fun findsSeededFoldersById() {
        seed(Fixtures.folder("f1"), Fixtures.folder("f2", name = "Moods"))

        assertEquals("Moods", store.byId("f2")?.name)
        assertNull(store.byId("missing"))
    }

    @Test
    fun fetchingAllReplacesTheList() = runTest(UnconfinedTestDispatcher()) {
        seed(Fixtures.folder("old"))
        h.on(HttpMethod.Get, "playlist-folders") { Fixtures.list(Fixtures.folder("f1"), Fixtures.folder("f2")) }

        store.fetchAll()

        assertEquals(listOf("f1", "f2"), store.folders.value.map { it.id })
    }

    @Test
    fun creatingPostsTheNameAndAppendsTheFolder() = runTest(UnconfinedTestDispatcher()) {
        seed(Fixtures.folder("f1"))
        h.on(HttpMethod.Post, "playlist-folders") { Fixtures.folder("f2", name = "Moods").toString() }

        val created = store.create("Moods")

        assertEquals(KoelJson.parseToJsonElement("""{"name":"Moods"}"""), h.requests.single().body)
        assertEquals("f2", created.id)
        assertEquals(listOf("f1", "f2"), store.folders.value.map { it.id })
    }

    @Test
    fun renamingPatchesTheNameAndAppliesItLocally() = runTest(UnconfinedTestDispatcher()) {
        val (folder) = seed(Fixtures.folder("f1"))
        h.on(HttpMethod.Patch, "playlist-folders/f1") { "" }

        store.rename(folder, "Renamed")

        assertEquals(KoelJson.parseToJsonElement("""{"name":"Renamed"}"""), h.requests.single().body)
        assertEquals("Renamed", store.byId("f1")?.name)
    }

    @Test
    fun removingDropsTheFolderBeforeTheServerAnswers() = runTest(UnconfinedTestDispatcher()) {
        val (folder) = seed(Fixtures.folder("f1"), Fixtures.folder("f2"))
        var idsDuringRequest = emptyList<String>()
        h.onRequest(HttpMethod.Delete, "playlist-folders/f1") {
            idsDuringRequest = store.folders.value.map { it.id }
            Harness.Reply(200, "")
        }

        store.remove(folder)

        assertEquals(listOf("f2"), idsDuringRequest)
        assertEquals(listOf("f2"), store.folders.value.map { it.id })
    }

    @Test
    fun removingRestoresTheFolderInPlaceWhenTheServerRefuses() = runTest(UnconfinedTestDispatcher()) {
        val (folder) = seed(Fixtures.folder("f1"), Fixtures.folder("f2"))
        h.on(HttpMethod.Delete, "playlist-folders/f1", status = 500) { "" }

        assertFailsWith<HttpResponseException> { store.remove(folder) }

        assertEquals(listOf("f1", "f2"), store.folders.value.map { it.id })
    }

    @Test
    fun resettingForgetsEveryFolder() {
        seed(Fixtures.folder("f1"))

        store.reset()

        assertTrue(store.folders.value.isEmpty())
    }
}
