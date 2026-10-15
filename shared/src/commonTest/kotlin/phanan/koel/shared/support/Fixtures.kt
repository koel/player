package phanan.koel.shared.support

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject

/** API-shaped JSON for fake server responses. */
object Fixtures {
    fun song(
        id: String,
        title: String = "Song $id",
        albumId: String = "album-1",
        albumName: String = "Album",
        artistId: String = "artist-1",
        artistName: String = "Artist",
        length: Double = 200.0,
        favorite: Boolean = false,
        playCount: Int = 0,
        track: Int = 1,
        disc: Int = 1,
        createdAt: String = "2024-01-01T00:00:00Z",
    ): JsonObject = buildJsonObject {
        put("type", "songs")
        put("id", id)
        put("title", title)
        put("lyrics", "")
        put("album_id", albumId)
        put("album_name", albumName)
        put("artist_id", artistId)
        put("artist_name", artistName)
        put("album_artist_id", artistId)
        put("album_artist_name", artistName)
        put("album_cover", "https://koel.test/img/$albumId.jpg")
        put("length", length)
        put("favorite", favorite)
        put("liked", favorite)
        put("play_count", playCount)
        put("track", track)
        put("disc", disc)
        put("genre", "Rock")
        put("year", 2020)
        put("created_at", createdAt)
    }

    fun episode(
        id: String,
        title: String = "Episode $id",
        podcastId: String = "podcast-1",
        length: Double = 1800.0,
    ): JsonObject = buildJsonObject {
        put("type", "episodes")
        put("id", id)
        put("title", title)
        put("length", length)
        put("podcast_id", podcastId)
        put("podcast_title", "Podcast")
        put("podcast_author", "Host")
        put("episode_description", "About $title")
        put("episode_image", "https://koel.test/img/$id.jpg")
        put("episode_link", "https://example.com/$id")
        put("created_at", "2024-01-01T00:00:00Z")
    }

    fun album(id: String, name: String = "Album $id", artistId: String = "artist-1", canEdit: Boolean = false, favorite: Boolean = false) =
        buildJsonObject {
            put("type", "albums")
            put("id", id)
            put("name", name)
            put("cover", "https://koel.test/img/$id.jpg")
            put("artist_id", artistId)
            put("artist_name", "Artist")
            put("year", 2020)
            put("favorite", favorite)
            putJsonObject("permissions") { put("edit", canEdit) }
        }

    fun artist(id: String, name: String = "Artist $id", canEdit: Boolean = false, favorite: Boolean = false) =
        buildJsonObject {
            put("type", "artists")
            put("id", id)
            put("name", name)
            put("image", "https://koel.test/img/$id.jpg")
            put("favorite", favorite)
            putJsonObject("permissions") { put("edit", canEdit) }
        }

    fun playlist(id: String, name: String = "Playlist $id", isSmart: Boolean = false, folderId: String? = null) =
        buildJsonObject {
            put("type", "playlists")
            put("id", id)
            put("name", name)
            put("is_smart", isSmart)
            put("folder_id", folderId)
            put("description", "")
            putJsonObject("permissions") {
                put("edit", true)
                put("delete", true)
            }
        }

    fun folder(id: String, name: String = "Folder $id") = buildJsonObject {
        put("id", id)
        put("name", name)
    }

    fun podcast(id: String, title: String = "Podcast $id", favorite: Boolean = false) = buildJsonObject {
        put("type", "podcasts")
        put("id", id)
        put("title", title)
        put("url", "https://example.com/$id.xml")
        put("link", "https://example.com/$id")
        put("description", "About $title")
        put("author", "Host")
        put("image", "https://koel.test/img/$id.jpg")
        put("subscribed_at", "2024-01-01T00:00:00Z")
        put("last_played_at", "2024-01-02T00:00:00Z")
        put("favorite", favorite)
        putJsonObject("state") {
            put("current_episode", null as String?)
            put("progresses", JsonArray(emptyList()))
        }
    }

    fun radioStation(id: String, name: String = "Station $id", favorite: Boolean = false) = buildJsonObject {
        put("type", "radio-stations")
        put("id", id)
        put("name", name)
        put("url", "https://stream.example.com/$id")
        put("logo", "https://koel.test/img/$id.png")
        put("description", "")
        put("is_public", false)
        put("favorite", favorite)
        putJsonObject("permissions") {
            put("edit", true)
            put("delete", true)
        }
    }

    fun genre(id: String, name: String = "Genre $id", songCount: Int = 10) = buildJsonObject {
        put("type", "genres")
        put("id", id)
        put("name", name)
        put("song_count", songCount)
        put("length", 3600)
    }

    fun user(id: String = "user-1", email: String = "me@koel.test") = buildJsonObject {
        put("type", "users")
        put("id", id)
        put("name", "Me")
        put("email", email)
        put("avatar", "https://koel.test/avatar.png")
        putJsonObject("preferences") {
            put("home_blocks_order", buildJsonArray { add(kotlinx.serialization.json.JsonPrimitive("recently_played_songs")) })
        }
    }

    fun page(items: List<JsonObject>, currentPage: Int = 1, hasNext: Boolean = false) = buildJsonObject {
        put("data", JsonArray(items))
        putJsonObject("links") { put("next", if (hasNext) "next" else null) }
        putJsonObject("meta") { put("current_page", currentPage) }
    }

    fun list(vararg items: JsonObject) = JsonArray(items.toList()).toString()
}
