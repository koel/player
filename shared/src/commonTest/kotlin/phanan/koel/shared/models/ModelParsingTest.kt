package phanan.koel.shared.models

import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.support.Fixtures
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ModelParsingTest {
    private fun playable(json: JsonObject): Playable = KoelJson.decodeFromJsonElement(Playable.serializer(), json)

    private fun JsonObject.with(vararg pairs: Pair<String, Any?>): JsonObject = JsonObject(this + pairs.associate { (key, value) ->
        key to when (value) {
            null -> kotlinx.serialization.json.JsonNull
            is Boolean -> JsonPrimitive(value)
            is Number -> JsonPrimitive(value)
            else -> JsonPrimitive(value.toString())
        }
    })

    @Test
    fun parsesSongsAndEpisodesByType() {
        assertIs<Song>(playable(Fixtures.song("s1")))
        assertIs<Episode>(playable(Fixtures.episode("e1")))
    }

    @Test
    fun prefersFavoriteOverTheLegacyLikedKey() {
        val base = Fixtures.song("s1")

        assertTrue(playable(base.with("favorite" to true, "liked" to false)).favorite)
        assertFalse(playable(base.with("favorite" to false, "liked" to true)).favorite)
        assertTrue(playable(JsonObject(base - "favorite").with("liked" to true)).favorite)
        assertTrue(playable(JsonObject(base - "favorite").with("liked" to 1)).favorite)
    }

    @Test
    fun acceptsNumericIdsAndStringYears() {
        val song = playable(Fixtures.song("s1").with("album_id" to 42, "artist_id" to 7, "year" to "1999")) as Song

        assertEquals("42", song.albumId)
        assertEquals("7", song.artistId)
        assertEquals(1999, song.year)
    }

    @Test
    fun toleratesMissingOptionalFields() {
        val song = playable(Fixtures.song("s1").with("track" to null, "disc" to null, "year" to null, "lyrics" to null)) as Song

        assertEquals(0, song.track)
        assertEquals(1, song.disc)
        assertNull(song.year)
        assertEquals("", song.lyrics)
    }

    @Test
    fun roundTripsPlayablesForOfflineStorage() {
        val original = listOf(playable(Fixtures.song("s1", favorite = true)), playable(Fixtures.episode("e1")))
        val serializer = ListSerializer(Playable.serializer())

        val restored = KoelJson.decodeFromString(serializer, KoelJson.encodeToString(serializer, original))

        assertEquals(original, restored)
    }

    @Test
    fun readsPermissionsAndDefaultsToNoAccess() {
        val editable = KoelJson.decodeFromJsonElement(Album.serializer(), Fixtures.album("a1", canEdit = true))
        val legacy = KoelJson.decodeFromJsonElement(Album.serializer(), JsonObject(Fixtures.album("a1") - "permissions"))

        assertTrue(editable.canEdit)
        assertFalse(legacy.canEdit)
    }

    @Test
    fun readsPodcastProgressesWhetherObjectOrEmptyArray() {
        val empty = KoelJson.decodeFromJsonElement(Podcast.serializer(), Fixtures.podcast("p1"))
        val withProgress = KoelJson.decodeFromString(
            Podcast.serializer(),
            """{"id":"p1","title":"P","state":{"current_episode":"e1","progresses":{"e1":12.5}}}""",
        )

        assertEquals(emptyMap(), empty.state.progresses)
        assertEquals(mapOf("e1" to 12.5), withProgress.state.progresses)
        assertEquals("e1", withProgress.state.currentEpisodeId)
    }

    @Test
    fun readsTheUsersHomeBlockOrder() {
        val user = KoelJson.decodeFromJsonElement(User.serializer(), Fixtures.user())

        assertEquals(listOf("recently_played_songs"), user.preferences.homeBlocksOrder)
    }

    @Test
    fun aUserWithTheRadioAbilityCanManageStations() {
        val user = KoelJson.decodeFromString(
            User.serializer(),
            """{"id":"u1","name":"Me","email":"me@koel.test","abilities":["manage songs","manage radio stations"]}""",
        )

        assertEquals(listOf("manage songs", "manage radio stations"), user.abilities)
        assertTrue(user.canManageRadioStations)
    }

    @Test
    fun aUserWithoutTheRadioAbilityCannotManageStations() {
        val user = KoelJson.decodeFromString(User.serializer(), """{"id":"u1","name":"Me","email":"me@koel.test","abilities":["manage songs"]}""")

        assertFalse(user.canManageRadioStations)
    }

    @Test
    fun aUserFromAServerWithoutAbilitiesCannotManageStations() {
        val user = KoelJson.decodeFromJsonElement(User.serializer(), Fixtures.user())

        assertEquals(emptyList(), user.abilities)
        assertFalse(user.canManageRadioStations)
    }
}
