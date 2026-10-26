package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RadioStationStoreTest {
    private val h = Harness()
    private val store = RadioStationStore(h.api)

    private suspend fun load(vararg stations: JsonObject): List<RadioStation> {
        h.on(HttpMethod.Get, "radio/stations") { Fixtures.list(*stations) }
        store.fetchAll()
        h.requests.clear()
        return store.stations.value
    }

    @Test
    fun fetchingAllReplacesTheList() = runTest(UnconfinedTestDispatcher()) {
        load(Fixtures.radioStation("old"))
        h.on(HttpMethod.Get, "radio/stations") { Fixtures.list(Fixtures.radioStation("s1"), Fixtures.radioStation("s2")) }

        store.fetchAll()

        assertEquals(listOf("s1", "s2"), store.stations.value.map { it.id })
    }

    @Test
    fun creatingPostsEveryFieldAndAppendsTheStation() = runTest(UnconfinedTestDispatcher()) {
        load(Fixtures.radioStation("s1"))
        h.on(HttpMethod.Post, "radio/stations") { Fixtures.radioStation("s2", name = "Jazz FM").toString() }

        val created = store.create("Jazz FM", "https://stream.example.com/jazz", description = "Smooth jazz", isPublic = true)

        assertEquals(
            KoelJson.parseToJsonElement(
                """{"name":"Jazz FM","url":"https://stream.example.com/jazz","is_public":true,"description":"Smooth jazz"}""",
            ),
            h.requests.single().body,
        )
        assertEquals("s2", created.id)
        assertTrue(created.canEdit)
        assertEquals(listOf("s1", "s2"), store.stations.value.map { it.id })
    }

    @Test
    fun creatingOmitsAnEmptyDescription() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Post, "radio/stations") { Fixtures.radioStation("s1").toString() }

        store.create("No Desc FM", "https://stream.example.com/x")

        assertEquals(
            KoelJson.parseToJsonElement("""{"name":"No Desc FM","url":"https://stream.example.com/x","is_public":false}"""),
            h.requests.single().body,
        )
    }

    @Test
    fun updatingPutsEveryFieldAndAppliesThemLocally() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1"))
        h.on(HttpMethod.Put, "radio/stations/s1") { "" }

        store.update(station, name = "New", url = "https://new/", description = "desc", isPublic = true)

        assertEquals(
            KoelJson.parseToJsonElement("""{"name":"New","url":"https://new/","description":"desc","homepage_url":null,"is_public":true}"""),
            h.requests.single().body,
        )
        val updated = store.stations.value.single()
        assertEquals("New", updated.name)
        assertEquals("https://new/", updated.url)
        assertEquals("desc", updated.description)
        assertTrue(updated.isPublic)
    }

    @Test
    fun updatingKeepsTheHomepageUrl() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1", homepageUrl = "https://jazz.example.com"))
        h.on(HttpMethod.Put, "radio/stations/s1") { "" }

        store.update(station, name = "New", url = station.url)

        assertEquals("\"https://jazz.example.com\"", h.requests.single().json.getValue("homepage_url").toString())
        assertEquals("https://jazz.example.com", store.byId("s1")?.homepageUrl)
    }

    @Test
    fun updatingSendsAMissingDescriptionAsAnEmptyString() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1"))
        h.on(HttpMethod.Put, "radio/stations/s1") { "" }

        store.update(station, name = "Same", url = station.url, description = null)

        assertEquals("\"\"", h.requests.single().json.getValue("description").toString())
        assertNull(store.byId("s1")?.description)
    }

    @Test
    fun removingDropsTheStationBeforeTheServerAnswers() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1"), Fixtures.radioStation("s2"))
        var idsDuringRequest = emptyList<String>()
        h.onRequest(HttpMethod.Delete, "radio/stations/s1") {
            idsDuringRequest = store.stations.value.map { it.id }
            Harness.Reply(200, "")
        }

        store.remove(station)

        assertEquals(listOf("s2"), idsDuringRequest)
        assertEquals(listOf("s2"), store.stations.value.map { it.id })
        assertNull(store.byId("s1"))
    }

    @Test
    fun removingRestoresTheStationInPlaceWhenTheServerRefuses() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1"), Fixtures.radioStation("s2"))
        h.on(HttpMethod.Delete, "radio/stations/s1", status = 500) { "" }

        assertFailsWith<HttpResponseException> { store.remove(station) }

        assertEquals(listOf("s1", "s2"), store.stations.value.map { it.id })
    }

    @Test
    fun togglingFavoriteFlipsRightAwayAndPostsTheToggle() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1"))
        var favoriteDuringRequest = false
        h.onRequest(HttpMethod.Post, "favorites/toggle") {
            favoriteDuringRequest = store.byId("s1")!!.favorite
            Harness.Reply(200, "")
        }

        store.toggleFavorite(station)

        assertEquals(KoelJson.parseToJsonElement("""{"type":"radio-station","id":"s1"}"""), h.requests.single().body)
        assertTrue(favoriteDuringRequest)
        assertTrue(store.stations.value.single().favorite)
    }

    @Test
    fun togglingFavoriteRollsBackWhenTheServerRefuses() = runTest(UnconfinedTestDispatcher()) {
        val (station) = load(Fixtures.radioStation("s1", favorite = true))
        h.on(HttpMethod.Post, "favorites/toggle", status = 500) { "" }

        assertFailsWith<HttpResponseException> { store.toggleFavorite(station) }

        assertTrue(store.stations.value.single().favorite)
    }

    @Test
    fun readsTheStreamTitleTheStationIsBroadcasting() = runTest(UnconfinedTestDispatcher()) {
        val (playing, silent) = load(Fixtures.radioStation("s1"), Fixtures.radioStation("s2"))
        h.on(HttpMethod.Get, "radio/stations/s1/now-playing") { """{"stream_title":"Artist - Song"}""" }
        h.on(HttpMethod.Get, "radio/stations/s2/now-playing") { """{"stream_title":null}""" }

        assertEquals("Artist - Song", store.nowPlaying(playing))
        assertNull(store.nowPlaying(silent))
    }

    @Test
    fun resettingForgetsEveryStation() = runTest(UnconfinedTestDispatcher()) {
        load(Fixtures.radioStation("s1"))

        store.reset()

        assertTrue(store.stations.value.isEmpty())
        assertNull(store.byId("s1"))
    }
}
