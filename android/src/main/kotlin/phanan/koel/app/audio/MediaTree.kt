package phanan.koel.app.audio

import android.net.Uri
import androidx.annotation.DrawableRes
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import phanan.koel.app.AppModel
import phanan.koel.app.R
import phanan.koel.shared.models.Playable

/**
 * The library as Android Auto browses it, in the same tabs as CarPlay. A playable item's id names
 * the list it came from, so picking it plays that list from there: `album:<id>|<songId>`,
 * `favorites|<songId>`.
 */
class MediaTree(private val app: AppModel, private val packageName: String) {
    val root: MediaItem = folder(ROOT, "Koel")

    /** The fixed folders, whose contents all change with who is logged in and whether the app is offline. */
    val folderIds = listOf(ROOT, RECENT, PLAYLISTS, LIBRARY, RADIO, FAVORITES, ALBUMS, ARTISTS, PODCASTS, DOWNLOADS)

    /** Null while nobody is logged in. */
    suspend fun children(parentId: String): List<MediaItem>? {
        app.launchWithoutScreen()
        if (!app.isReady && !app.playsDownloadsOnly) return null

        val core = app.core
        return when {
            parentId == ROOT && app.playsDownloadsOnly -> listOf(folder(DOWNLOADS, "Downloaded", icon = R.drawable.ic_car_downloaded))
            parentId == ROOT -> listOf(
                folder(RECENT, "Recently Played", icon = R.drawable.ic_car_recent),
                folder(PLAYLISTS, "Playlists", icon = R.drawable.ic_car_playlists),
                folder(LIBRARY, "Library", icon = R.drawable.ic_car_library),
                folder(RADIO, "Radio", icon = R.drawable.ic_car_radio),
            )
            parentId == LIBRARY -> listOf(
                folder(FAVORITES, "Favorites", icon = R.drawable.ic_car_favorites),
                folder(ALBUMS, "Albums", icon = R.drawable.ic_car_albums),
                folder(ARTISTS, "Artists", icon = R.drawable.ic_car_artists),
                folder(PODCASTS, "Podcasts", icon = R.drawable.ic_car_podcasts),
                folder(DOWNLOADS, "Downloaded", icon = R.drawable.ic_car_downloaded),
            )
            parentId == PLAYLISTS -> {
                core.playlists.fetchAll()
                core.playlists.playlists.value.sortedBy { it.name.lowercase() }.map {
                    folder("$PLAYLIST_PREFIX${it.id}", it.name, artworkUrl = it.cover)
                }
            }
            parentId == ALBUMS -> {
                if (core.albums.items.value.isEmpty()) core.albums.loadMore()
                core.albums.items.value.map { folder("$ALBUM_PREFIX${it.id}", it.name, subtitle = it.artistName, artworkUrl = it.cover) }
            }
            parentId == ARTISTS -> {
                if (core.artists.items.value.isEmpty()) core.artists.loadMore()
                core.artists.items.value.map { folder("$ARTIST_PREFIX${it.id}", it.name, artworkUrl = it.imageUrl) }
            }
            parentId == PODCASTS -> {
                core.podcasts.fetchAll()
                core.podcasts.podcasts.value.map { folder("$PODCAST_PREFIX${it.id}", it.title, subtitle = it.author, artworkUrl = it.imageUrl) }
            }
            parentId == RADIO -> {
                core.radioStations.fetchAll()
                core.radioStations.stations.value.map {
                    playableItem("$STATION_PREFIX${it.id}", it.name, it.description, it.logo)
                }
            }
            else -> playables(parentId).map { playableItem("$parentId|${it.id}", it.title, it.subtitle, it.artworkUrl) }
        }.take(MAX_ITEMS)
    }

    suspend fun play(mediaId: String) {
        app.launchWithoutScreen()
        if (mediaId.startsWith(STATION_PREFIX)) {
            val station = app.core.radioStations.byId(mediaId.removePrefix(STATION_PREFIX)) ?: return
            app.core.player.playRadio(station)
            return
        }
        val (list, playableId) = playableLocation(mediaId) ?: return
        val playables = playables(list)
        playables.firstOrNull { it.id == playableId }?.let { app.actions.playFrom(it, playables) }
    }

    /** Only tells a folder from something to play, which is all subscribing to a folder checks. */
    fun itemById(mediaId: String): MediaItem {
        val isPlayable = mediaId.startsWith(STATION_PREFIX) || playableLocation(mediaId) != null
        return item(mediaId, title = "", subtitle = null, artworkUrl = null, isBrowsable = !isPlayable)
    }

    private suspend fun playables(list: String): List<Playable> {
        val core = app.core
        return when {
            list == RECENT -> core.recentlyPlayed.fetch()
            list == FAVORITES -> core.favorites.fetch()
            list == DOWNLOADS -> core.downloads.playables.value
            list.startsWith(PLAYLIST_PREFIX) -> core.playables.fetchForPlaylist(list.removePrefix(PLAYLIST_PREFIX))
            list.startsWith(ALBUM_PREFIX) -> core.playables.fetchForAlbum(list.removePrefix(ALBUM_PREFIX))
            list.startsWith(ARTIST_PREFIX) -> core.playables.fetchForArtist(list.removePrefix(ARTIST_PREFIX))
            list.startsWith(PODCAST_PREFIX) -> core.playables.fetchForPodcast(list.removePrefix(PODCAST_PREFIX))
            else -> emptyList()
        }
    }

    private fun folder(id: String, title: String, subtitle: String? = null, artworkUrl: String? = null, @DrawableRes icon: Int? = null) =
        item(id, title, subtitle, icon?.let { "android.resource://$packageName/$it" } ?: artworkUrl, isBrowsable = true)

    private fun playableItem(id: String, title: String, subtitle: String?, artworkUrl: String?) =
        item(id, title, subtitle, artworkUrl, isBrowsable = false)

    private fun item(id: String, title: String, subtitle: String?, artworkUrl: String?, isBrowsable: Boolean) =
        MediaItem.Builder()
            .setMediaId(id)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(title)
                    .setArtist(subtitle)
                    .setArtworkUri(artworkUrl?.takeIf { it.isNotBlank() }?.let(Uri::parse))
                    .setIsBrowsable(isBrowsable)
                    .setIsPlayable(!isBrowsable)
                    .build(),
            )
            .build()

    companion object {
        /** The list a playable item came from, and the playable's own id. */
        fun playableLocation(mediaId: String): Pair<String, String>? {
            val separator = mediaId.indexOf('|')
            if (separator <= 0 || separator == mediaId.lastIndex) return null
            return mediaId.substring(0, separator) to mediaId.substring(separator + 1)
        }

        private const val ROOT = "root"
        private const val RECENT = "recent"
        private const val PLAYLISTS = "playlists"
        private const val ALBUMS = "albums"
        private const val ARTISTS = "artists"
        private const val LIBRARY = "library"
        private const val FAVORITES = "favorites"
        private const val PODCASTS = "podcasts"
        private const val DOWNLOADS = "downloads"
        private const val RADIO = "radio"
        private const val PLAYLIST_PREFIX = "playlist:"
        private const val ALBUM_PREFIX = "album:"
        private const val ARTIST_PREFIX = "artist:"
        private const val PODCAST_PREFIX = "podcast:"
        private const val STATION_PREFIX = "station:"

        /** Android Auto lists only so many items, and long lists are slow to scroll in a car. */
        private const val MAX_ITEMS = 200
    }
}
