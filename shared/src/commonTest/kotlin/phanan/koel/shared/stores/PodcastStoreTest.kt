package phanan.koel.shared.stores

import io.ktor.http.HttpMethod
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Podcast
import phanan.koel.shared.models.PodcastSortField
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.models.sorted
import phanan.koel.shared.support.Fixtures
import phanan.koel.shared.support.Harness
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class PodcastStoreTest {
    private val h = Harness()
    private val store = PodcastStore(h.api)

    private suspend fun subscribe(vararg podcasts: JsonObject): List<Podcast> {
        h.on(HttpMethod.Get, "podcasts") { Fixtures.list(*podcasts) }
        store.fetchAll()
        h.requests.clear()
        return store.podcasts.value
    }

    private fun episode(id: String, podcastId: String) =
        KoelJson.decodeFromJsonElement(Episode.serializer(), Fixtures.episode(id, podcastId = podcastId))

    private fun podcastWithProgress(id: String, episodeId: String, seconds: Double) = buildJsonObject {
        Fixtures.podcast(id).forEach { (key, value) -> put(key, value) }
        putJsonObject("state") {
            put("current_episode", episodeId)
            putJsonObject("progresses") { put(episodeId, seconds) }
        }
    }

    @Test
    fun fetchingAllReplacesTheList() = runTest(UnconfinedTestDispatcher()) {
        subscribe(Fixtures.podcast("old"))
        h.on(HttpMethod.Get, "podcasts") { Fixtures.list(Fixtures.podcast("p1"), Fixtures.podcast("p2")) }

        store.fetchAll()

        assertEquals(listOf("p1", "p2"), store.podcasts.value.map { it.id })
    }

    @Test
    fun refreshingReloadsPodcastsResolvedEarlier() = runTest(UnconfinedTestDispatcher()) {
        subscribe(Fixtures.podcast("p1"))
        h.on(HttpMethod.Get, "podcasts/other") { Fixtures.podcast("other").toString() }
        store.resolve("other")

        store.refresh()
        store.resolve("other")

        assertEquals(2, h.requestsTo(HttpMethod.Get, "podcasts/other").size)
        assertEquals(listOf("p1"), store.podcasts.value.map { it.id })
    }

    @Test
    fun togglingFavoriteFlipsRightAwayAndPostsTheToggle() = runTest(UnconfinedTestDispatcher()) {
        val (podcast) = subscribe(Fixtures.podcast("p1"))
        var favoriteDuringRequest = false
        h.onRequest(HttpMethod.Post, "favorites/toggle") {
            favoriteDuringRequest = store.byId("p1")!!.favorite
            Harness.Reply(200, "")
        }

        store.toggleFavorite(podcast)

        assertEquals(KoelJson.parseToJsonElement("""{"type":"podcast","id":"p1"}"""), h.requests.single().body)
        assertTrue(favoriteDuringRequest)
        assertTrue(store.podcasts.value.single().favorite)
    }

    @Test
    fun togglingFavoriteRollsBackWhenTheServerRefuses() = runTest(UnconfinedTestDispatcher()) {
        val (podcast) = subscribe(Fixtures.podcast("p1", favorite = true))
        h.on(HttpMethod.Post, "favorites/toggle", status = 500) { "" }

        assertFailsWith<HttpResponseException> { store.toggleFavorite(podcast) }

        assertTrue(store.podcasts.value.single().favorite)
    }

    @Test
    fun unsubscribingDropsThePodcastBeforeTheServerAnswers() = runTest(UnconfinedTestDispatcher()) {
        val (podcast) = subscribe(Fixtures.podcast("p1"), Fixtures.podcast("p2"))
        var idsDuringRequest = emptyList<String>()
        h.onRequest(HttpMethod.Delete, "podcasts/p1/subscriptions") {
            idsDuringRequest = store.podcasts.value.map { it.id }
            Harness.Reply(200, "")
        }

        store.unsubscribe(podcast)

        assertEquals(listOf("p2"), idsDuringRequest)
        assertEquals(listOf("p2"), store.podcasts.value.map { it.id })
        assertNull(store.byId("p1"))
    }

    @Test
    fun unsubscribingRestoresThePodcastInPlaceWhenTheServerRefuses() = runTest(UnconfinedTestDispatcher()) {
        val (podcast) = subscribe(Fixtures.podcast("p1"), Fixtures.podcast("p2"))
        h.on(HttpMethod.Delete, "podcasts/p1/subscriptions", status = 500) { "" }

        assertFailsWith<HttpResponseException> { store.unsubscribe(podcast) }

        assertEquals(listOf("p1", "p2"), store.podcasts.value.map { it.id })
    }

    @Test
    fun addingPostsTheFeedUrlAndAppendsThePodcast() = runTest(UnconfinedTestDispatcher()) {
        subscribe(Fixtures.podcast("p1"))
        h.on(HttpMethod.Post, "podcasts") { Fixtures.podcast("p2", title = "Added").toString() }

        val added = store.add("https://example.com/feed.xml")

        assertEquals(KoelJson.parseToJsonElement("""{"url":"https://example.com/feed.xml"}"""), h.requests.single().body)
        assertEquals("Added", added.title)
        assertEquals(listOf("p1", "p2"), store.podcasts.value.map { it.id })
    }

    @Test
    fun addingWaitsForASlowFeedLongerThanOtherRequests() = runTest(UnconfinedTestDispatcher()) {
        h.onRequest(HttpMethod.Post, "podcasts") {
            delay(300.milliseconds)
            Harness.Reply(200, Fixtures.podcast("p1").toString())
        }
        val impatientStore = PodcastStore(ApiClient(h.engine, h.preferences, stallTimeout = 100.milliseconds))

        assertEquals("p1", impatientStore.add("https://example.com/feed.xml").id)
    }

    @Test
    fun resolvingUsesTheCacheUntilForcedToRefresh() = runTest(UnconfinedTestDispatcher()) {
        var title = "First"
        h.on(HttpMethod.Get, "podcasts/p1") { Fixtures.podcast("p1", title = title).toString() }

        store.resolve("p1")
        title = "Second"

        assertEquals("First", store.resolve("p1").title)
        assertEquals("Second", store.resolve("p1", forceRefresh = true).title)
        assertEquals(2, h.requestsTo(HttpMethod.Get, "podcasts/p1").size)
    }

    @Test
    fun observingFollowsChangesToThePodcast() = runTest(UnconfinedTestDispatcher()) {
        val (podcast) = subscribe(Fixtures.podcast("p1"))
        h.on(HttpMethod.Post, "favorites/toggle") { "" }

        store.toggleFavorite(podcast)

        assertTrue(store.observe("p1").first()!!.favorite)
        assertNull(store.observe("missing").first())
    }

    @Test
    fun readsEpisodeProgressFromThePodcastState() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "podcasts/p1") { podcastWithProgress("p1", "e1", 42.5).toString() }

        assertEquals(42.5, store.episodeProgress(episode("e1", podcastId = "p1")))
        assertEquals(0.0, store.episodeProgress(episode("e2", podcastId = "p1")))
    }

    @Test
    fun episodeProgressIsZeroWhenThePodcastCannotBeLoaded() = runTest(UnconfinedTestDispatcher()) {
        h.on(HttpMethod.Get, "podcasts/p1", status = 500) { "" }

        assertEquals(0.0, store.episodeProgress(episode("e1", podcastId = "p1")))
    }

    @Test
    fun resettingForgetsEveryPodcast() = runTest(UnconfinedTestDispatcher()) {
        subscribe(Fixtures.podcast("p1"))

        store.reset()

        assertTrue(store.podcasts.value.isEmpty())
        assertNull(store.byId("p1"))
    }

    @Test
    fun sortsByEveryField() {
        val podcasts = listOf(
            sortable("p1", title = "Beta", author = "Zed", subscribedAt = "2024-03-01", lastPlayedAt = "2024-05-01"),
            sortable("p2", title = "Alpha", author = "Amy", subscribedAt = "2024-01-01", lastPlayedAt = "2024-06-01"),
            sortable("p3", title = "Gamma", author = "Max", subscribedAt = "2024-02-01", lastPlayedAt = "2024-04-01"),
        )

        assertEquals(listOf("p2", "p1", "p3"), podcasts.sorted(PodcastSortField.LAST_PLAYED_AT, SortOrder.DESC).map { it.id })
        assertEquals(listOf("p2", "p3", "p1"), podcasts.sorted(PodcastSortField.SUBSCRIBED_AT, SortOrder.ASC).map { it.id })
        assertEquals(listOf("p2", "p1", "p3"), podcasts.sorted(PodcastSortField.TITLE, SortOrder.ASC).map { it.id })
        assertEquals(listOf("p1", "p3", "p2"), podcasts.sorted(PodcastSortField.AUTHOR, SortOrder.DESC).map { it.id })
    }

    private fun sortable(id: String, title: String, author: String, subscribedAt: String, lastPlayedAt: String) =
        Podcast(id = id, title = title, author = author, subscribedAt = subscribedAt, lastPlayedAt = lastPlayedAt)
}
