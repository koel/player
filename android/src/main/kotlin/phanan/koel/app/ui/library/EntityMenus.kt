package phanan.koel.app.ui.library

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.PlaylistPlay
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.FolderOff
import androidx.compose.material.icons.filled.HeartBroken
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.filled.Shuffle
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.MicExternalOn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import phanan.koel.app.AppModel
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.collections.ArtistInfoSheet
import phanan.koel.app.ui.collections.YearInput
import phanan.koel.app.ui.collections.hasBrowsableArtist
import phanan.koel.app.ui.collections.kindLabel
import phanan.koel.app.ui.components.ActionsSheet
import phanan.koel.app.ui.components.ConfirmDialog
import phanan.koel.app.ui.components.FormField
import phanan.koel.app.ui.components.FormFieldKind
import phanan.koel.app.ui.components.FormSheet
import phanan.koel.app.ui.components.MenuAction
import phanan.koel.app.ui.components.PreviewCard
import phanan.koel.app.ui.components.SheetTitle
import phanan.koel.app.ui.main.Route
import phanan.koel.shared.api.HttpResponseException
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Playlist
import phanan.koel.shared.models.Podcast
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.session.Feature

/** What the menus and swipes do with albums, artists, playlists, podcasts and stations, with iOS's toasts. */
class EntityActions(private val app: AppModel) {
    private val scope = MainScope()
    private val player get() = app.core.player

    val supportsFavorites: Boolean get() = app.core.session.supports(Feature.FAVORITE_ENTITIES)

    private fun attempt(failureMessage: String? = null, action: suspend () -> Unit) {
        scope.launch { runCatching { action() }.onFailure { app.messages.showError(message = failureMessage) } }
    }

    /** Fetches a collection's songs, then plays or queues them the way the song menus do. */
    private fun withSongs(fetch: suspend () -> List<Playable>, action: (List<Playable>) -> Unit) = attempt {
        val songs = fetch()
        if (songs.isNotEmpty()) action(songs)
    }

    /** Play, Shuffle, Play Next and Play Last: on [playables] a screen already shows, or else on what [fetch] gets when one is picked. */
    private fun queueMenu(playables: List<Playable>?, fetch: suspend () -> List<Playable>, startsSection: Boolean): List<MenuAction> {
        val isEnabled = playables == null || playables.isNotEmpty()
        fun withQueued(action: (List<Playable>) -> Unit) = if (playables == null) withSongs(fetch, action) else action(playables)
        return listOf(
            MenuAction("Play", Icons.Default.PlayArrow, isEnabled = isEnabled, startsSection = startsSection) { withQueued { app.actions.play(it) } },
            MenuAction("Shuffle", Icons.Default.Shuffle, isEnabled = isEnabled) { withQueued { app.actions.play(it, shuffled = true) } },
            MenuAction("Play Next", Icons.AutoMirrored.Filled.PlaylistPlay, isEnabled = isEnabled) { withQueued { app.actions.playNext(it) } },
            MenuAction("Play Last", Icons.AutoMirrored.Filled.QueueMusic, isEnabled = isEnabled) { withQueued { app.actions.playLast(it) } },
        )
    }

    private fun favoriteAction(isFavorite: Boolean, toggle: suspend () -> Unit) =
        MenuAction(if (isFavorite) "Undo Favorite" else "Favorite", if (isFavorite) Icons.Default.HeartBroken else Icons.Default.FavoriteBorder, isEnabled = !app.isOffline) {
            attempt { toggle() }
        }

    fun albumSongs(album: Album): suspend () -> List<Playable> = { app.core.playables.fetchForAlbum(album.id) }

    fun artistSongs(artist: Artist): suspend () -> List<Playable> = { app.core.playables.fetchForArtist(artist.id) }

    fun playLast(artist: Artist) = withSongs(artistSongs(artist)) { app.actions.playLast(it) }

    fun playLast(album: Album) = withSongs(albumSongs(album)) { app.actions.playLast(it) }

    /** [playables] are the album's songs when the screen has them; otherwise the queue actions fetch them. */
    fun albumMenu(album: Album, onEdit: (() -> Unit)?, playables: List<Playable>? = null): List<MenuAction> = buildList {
        if (supportsFavorites) add(favoriteAction(album.favorite) { app.core.albums.toggleFavorite(album) })
        addAll(queueMenu(playables, albumSongs(album), startsSection = isNotEmpty()))
        val canGoToArtist = album.hasBrowsableArtist && !app.isOffline
        if (canGoToArtist) {
            add(MenuAction("Go to Artist", Icons.Outlined.MicExternalOn, startsSection = true) { app.navigator.push(Route.Artist(album.artistId)) })
        }
        if (album.canEdit && onEdit != null && !app.isOffline) {
            add(MenuAction("Edit…", Icons.Default.Edit, startsSection = !canGoToArtist, onClick = onEdit))
        }
    }

    /** [playables] are the artist's songs when the screen has them; otherwise the queue actions fetch them. */
    fun artistMenu(artist: Artist, onInfo: () -> Unit, onEdit: (() -> Unit)?, playables: List<Playable>? = null): List<MenuAction> = buildList {
        if (supportsFavorites) add(favoriteAction(artist.favorite) { app.core.artists.toggleFavorite(artist) })
        add(MenuAction("Info", Icons.Outlined.Info, isEnabled = !app.isOffline, onClick = onInfo))
        addAll(queueMenu(playables, artistSongs(artist), startsSection = true))
        if (artist.canEdit && onEdit != null && !app.isOffline) add(MenuAction("Edit…", Icons.Default.Edit, startsSection = true, onClick = onEdit))
    }

    /** Queues every song of [playlists] at the end, as the Flutter swipe did. */
    fun queue(playlists: List<Playlist>) = attempt {
        val songs = playlists.flatMap { runCatching { app.core.playables.fetchForPlaylist(it.id) }.getOrDefault(emptyList()) }
        if (songs.isEmpty()) app.messages.show("No songs found.", icon = Icons.Default.RemoveCircleOutline) else app.actions.playLast(songs)
    }

    fun delete(playlist: Playlist) = attempt("Could not delete playlist.") {
        app.core.playlists.remove(playlist)
        app.messages.show("Playlist deleted", icon = Icons.Default.Delete)
    }

    fun move(playlist: Playlist, folderId: String?) = attempt("Could not update playlist.") {
        app.core.playlists.update(playlist, playlist.name, playlist.description, folderId)
        app.messages.show("Playlist updated")
    }

    /** [playables] are the playlist's songs when the screen has them; otherwise Play Last fetches them. */
    fun playlistMenu(playlist: Playlist, onEdit: () -> Unit, onMove: () -> Unit, onDelete: () -> Unit, playables: List<Playable>? = null): List<MenuAction> = buildList {
        add(
            MenuAction("Play Last", Icons.AutoMirrored.Filled.QueueMusic, isEnabled = playables?.isNotEmpty() ?: true) {
                if (playables == null) queue(listOf(playlist)) else app.actions.playLast(playables)
            },
        )
        if (playlist.canEdit && !app.isOffline) {
            add(MenuAction("Edit…", Icons.Default.Edit, startsSection = true, onClick = onEdit))
            if (app.core.playlistFolders.folders.value.isNotEmpty()) add(MenuAction("Move to Folder", Icons.Default.Folder, onClick = onMove))
        }
        if (playlist.canDelete && !app.isOffline) add(MenuAction("Delete", Icons.Default.Delete, isDestructive = true, startsSection = true, onClick = onDelete))
    }

    /** Picks up the episode in progress if there is one, otherwise plays from the top. [episodes] skips fetching them. */
    fun play(podcast: Podcast, shuffled: Boolean = false, episodes: List<Playable>? = null) = attempt {
        val all = episodes ?: app.core.playables.fetchForPodcast(podcast.id)
        if (all.isEmpty()) return@attempt
        val current = all.firstOrNull { it.id == podcast.state.currentEpisodeId }
        if (!shuffled && current != null) app.actions.playFrom(current, all) else app.actions.play(all, shuffled)
    }

    suspend fun checkForNewEpisodes(podcast: Podcast) {
        runCatching { app.core.playables.fetchForPodcast(podcast.id, checkForNewEpisodes = true) }
            .onSuccess { app.messages.show("Feed refreshed", icon = Icons.Default.Refresh) }
            .onFailure { app.messages.showError("Refresh failed") }
    }

    fun unsubscribe(podcast: Podcast) = attempt("Could not unsubscribe.") {
        app.core.podcasts.unsubscribe(podcast)
        app.messages.show("Unsubscribed", icon = Icons.Default.RemoveCircleOutline)
    }

    /** [episodes] are the podcast's episodes when the screen has them; otherwise playing fetches them. */
    fun podcastMenu(podcast: Podcast, onUnsubscribe: () -> Unit, episodes: List<Playable>? = null): List<MenuAction> = buildList {
        val canPlay = episodes?.isNotEmpty() ?: true
        add(MenuAction(if (podcast.state.currentEpisodeId == null) "Play All" else "Continue", Icons.Default.PlayArrow, isEnabled = canPlay) { play(podcast, episodes = episodes) })
        add(MenuAction("Shuffle", Icons.Default.Shuffle, isEnabled = canPlay) { play(podcast, shuffled = true, episodes = episodes) })
        if (supportsFavorites) add(favoriteAction(podcast.favorite) { app.core.podcasts.toggleFavorite(podcast) }.withSectionStart())
        add(MenuAction("Refresh", Icons.Default.Refresh, isEnabled = !app.isOffline, startsSection = !supportsFavorites) { scope.launch { checkForNewEpisodes(podcast) } })
        add(MenuAction("Unsubscribe", Icons.Default.RemoveCircleOutline, isDestructive = true, isEnabled = !app.isOffline, startsSection = true, onClick = onUnsubscribe))
    }

    fun isCurrent(station: RadioStation) = player.state.value.radioStation?.id == station.id

    fun isLive(station: RadioStation) = isCurrent(station) && player.state.value.let { it.isPlaying || it.isBuffering }

    fun play(station: RadioStation) = attempt("Could not play station.") { player.playRadio(station) }

    fun delete(station: RadioStation) = attempt("Could not delete station.") {
        app.core.radioStations.remove(station)
        app.messages.show("Station deleted", icon = Icons.Default.Delete)
    }

    fun stationMenu(station: RadioStation, onEdit: () -> Unit, onDelete: () -> Unit): List<MenuAction> = buildList {
        if (isLive(station)) {
            add(MenuAction("Stop", Icons.Default.Stop) { player.stopRadio() })
        } else {
            add(MenuAction("Play", Icons.Default.PlayArrow) { play(station) })
        }
        if (supportsFavorites) add(favoriteAction(station.favorite) { app.core.radioStations.toggleFavorite(station) })
        if (station.canEdit && !app.isOffline) add(MenuAction("Edit…", Icons.Default.Edit, startsSection = true, onClick = onEdit))
        if (station.canDelete && !app.isOffline) add(MenuAction("Delete", Icons.Default.Delete, isDestructive = true, startsSection = !station.canEdit, onClick = onDelete))
    }
}

private fun MenuAction.withSectionStart() = MenuAction(label, icon, isDestructive, isEnabled, startsSection = true, onClick = onClick)

/** An album's long-press menu, with its Edit sheet. */
@Composable
fun AlbumMenuSheet(album: Album, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    var isEditing by remember { mutableStateOf(false) }
    if (isEditing) {
        AlbumEditSheet(album, onDismiss = onDismiss)
        return
    }
    ActionsSheet(onDismiss, remember(album) { EntityActions(app) }.albumMenu(album, onEdit = { isEditing = true })) {
        PreviewCard(album.cover, album.name, album.artistName)
    }
}

/** An artist's long-press menu, with its Info and Edit sheets. */
@Composable
fun ArtistMenuSheet(artist: Artist, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    var shown by remember { mutableStateOf<String?>(null) }
    when (shown) {
        "info" -> ArtistInfoSheet(artist, onDismiss)
        "edit" -> ArtistEditSheet(artist, onDismiss)
        else -> ActionsSheet(onDismiss, remember(artist) { EntityActions(app) }.artistMenu(artist, onInfo = { shown = "info" }, onEdit = { shown = "edit" })) {
            PreviewCard(artist.imageUrl, artist.name, null, isCircular = true)
        }
    }
}

@Composable
fun AlbumEditSheet(album: Album, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    FormSheet(
        title = "Edit Album",
        fields = listOf(
            FormField("Album Name", album.name, isRequired = true),
            FormField("Year (optional)", album.year?.toString().orEmpty(), keyboardType = KeyboardType.Number, sanitize = YearInput::sanitized),
        ),
        onDismiss = onDismiss,
    ) { (name, year) ->
        runCatching { app.core.albums.update(album, name, YearInput.value(year)) }
            .getOrElse { throw Exception("Could not update album.") }
        app.messages.show("Album updated")
    }
}

@Composable
fun ArtistEditSheet(artist: Artist, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    FormSheet(title = "Edit Artist", fields = listOf(FormField("Artist Name", artist.name, isRequired = true)), onDismiss = onDismiss) { (name) ->
        runCatching { app.core.artists.update(artist, name) }.getOrElse { throw Exception("Could not update artist.") }
        app.messages.show("Artist updated")
    }
}

/** New Playlist when [playlist] is null, otherwise Edit Playlist; both offer a folder when there are folders. */
@Composable
fun PlaylistFormSheet(playlist: Playlist?, onDismiss: () -> Unit, onCreate: (Playlist) -> Unit = {}) {
    val app = LocalAppModel.current
    val folders by app.core.playlistFolders.folders.collectAsStateWithLifecycle()
    val folderField = if (folders.isEmpty()) {
        null
    } else {
        FormField("Folder", playlist?.folderId.orEmpty(), kind = FormFieldKind.Picker(listOf("" to "No folder") + folders.sortedBy { it.name.lowercase() }.map { it.id to it.name }))
    }
    FormSheet(
        title = if (playlist == null) "New Playlist" else "Edit Playlist",
        fields = listOfNotNull(
            FormField("Playlist Name", playlist?.name.orEmpty(), isRequired = true),
            FormField("Description (optional)", playlist?.description.orEmpty(), isSingleLine = false),
            folderField,
        ),
        submitLabel = if (playlist == null) "Create" else "Save",
        onDismiss = onDismiss,
    ) { values ->
        val description = values[1].ifBlank { null }
        val folderId = values.getOrNull(2)?.ifBlank { null }
        if (playlist == null) {
            val created = runCatching { app.core.playlists.create(values[0], description, folderId) }.getOrElse { throw Exception("Could not create playlist.") }
            app.messages.show("Playlist added")
            onCreate(created)
        } else {
            runCatching { app.core.playlists.update(playlist, values[0], description, folderId) }.getOrElse { throw Exception("Could not update playlist.") }
            app.messages.show("Playlist updated")
        }
    }
}

/** A playlist's long-press menu, with its Edit, Move to Folder and Delete flows. */
@Composable
fun PlaylistMenuSheet(playlist: Playlist, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    var shown by remember { mutableStateOf<String?>(null) }
    when (shown) {
        "edit" -> PlaylistFormSheet(playlist, onDismiss)
        "move" -> FolderPickerSheet(playlist, onDismiss) { actions.move(playlist, it) }
        "delete" -> PlaylistDeletion(playlist, onDismiss) { actions.delete(playlist) }
        else -> ActionsSheet(onDismiss, actions.playlistMenu(playlist, onEdit = { shown = "edit" }, onMove = { shown = "move" }, onDelete = { shown = "delete" })) {
            PreviewCard(playlist.cover, playlist.name, playlist.kindLabel)
        }
    }
}

@Composable
fun PlaylistDeletion(playlist: Playlist, onDismiss: () -> Unit, onDelete: () -> Unit) {
    ConfirmDialog(
        title = "Delete playlist?",
        message = "Delete “${playlist.name}”? This cannot be undone.",
        confirmLabel = "Delete",
        onDismiss = onDismiss,
        onConfirm = onDelete,
    )
}

@Composable
fun FolderPickerSheet(playlist: Playlist, onDismiss: () -> Unit, onPick: (String?) -> Unit) {
    val app = LocalAppModel.current
    val folders by app.core.playlistFolders.folders.collectAsStateWithLifecycle()
    val options = listOf<Pair<String?, String>>(null to "No folder") + folders.sortedBy { it.name.lowercase() }.map { it.id to it.name }
    ActionsSheet(
        onDismiss,
        options.map { (id, name) ->
            MenuAction(name, if (playlist.folderId == id) Icons.Default.Check else if (id == null) Icons.Default.FolderOff else Icons.Default.Folder) {
                if (playlist.folderId != id) onPick(id)
            }
        },
    ) {
        SheetTitle("Move to Folder", Modifier.padding(horizontal = 20.dp, vertical = 12.dp))
    }
}

@Composable
fun FolderFormSheet(onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    FormSheet(title = "New Folder", fields = listOf(FormField("Folder Name", isRequired = true)), submitLabel = "Create", onDismiss = onDismiss) { (name) ->
        runCatching { app.core.playlistFolders.create(name) }.getOrElse { throw Exception("Could not create folder.") }
        app.messages.show("Folder created", icon = Icons.Default.Folder)
    }
}

/** A podcast's long-press menu, with its Unsubscribe confirmation. */
@Composable
fun PodcastMenuSheet(podcast: Podcast, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    var isConfirming by remember { mutableStateOf(false) }
    if (isConfirming) {
        PodcastUnsubscribe(podcast, onDismiss) { actions.unsubscribe(podcast) }
        return
    }
    ActionsSheet(onDismiss, actions.podcastMenu(podcast, onUnsubscribe = { isConfirming = true })) {
        PreviewCard(podcast.imageUrl, podcast.title, podcast.author)
    }
}

@Composable
fun PodcastUnsubscribe(podcast: Podcast, onDismiss: () -> Unit, onUnsubscribe: () -> Unit) {
    ConfirmDialog(
        title = "Unsubscribe?",
        message = "Unsubscribe from “${podcast.title}”?",
        confirmLabel = "Unsubscribe",
        onDismiss = onDismiss,
        onConfirm = onUnsubscribe,
    )
}

@Composable
fun AddPodcastSheet(onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    FormSheet(
        title = "Add Podcast",
        fields = listOf(FormField("Podcast RSS URL", isRequired = true, keyboardType = KeyboardType.Uri)),
        submitLabel = "Add",
        onDismiss = onDismiss,
    ) { (url) ->
        if (!url.isWebUrl) throw Exception("Enter a valid http or https address.")
        runCatching { app.core.podcasts.add(url) }.getOrElse { throw Exception(podcastAddFailureMessage((it as? HttpResponseException)?.statusCode)) }
        app.messages.show("Podcast added")
    }
}

/** New Station when [station] is null, otherwise Edit Station. */
@Composable
fun RadioStationFormSheet(station: RadioStation?, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    FormSheet(
        title = if (station == null) "New Station" else "Edit Station",
        fields = listOf(
            FormField("Station Name", station?.name.orEmpty(), isRequired = true),
            FormField("Stream URL", station?.url.orEmpty(), isRequired = true, keyboardType = KeyboardType.Uri),
            FormField("Description (optional)", station?.description.orEmpty(), isSingleLine = false),
            FormField("Accessible to all users", (station?.isPublic ?: false).toString(), kind = FormFieldKind.Toggle),
        ),
        submitLabel = if (station == null) "Add" else "Save",
        onDismiss = onDismiss,
    ) { (name, url, description, isPublic) ->
        if (!url.isWebUrl) throw Exception("Enter a valid http or https stream address.")
        val stations = app.core.radioStations
        if (station == null) {
            runCatching { stations.create(name, url, description.ifBlank { null }, isPublic.toBoolean()) }.getOrElse { throw Exception("Could not add station.") }
            app.messages.show("Station added")
        } else {
            runCatching { stations.update(station, name, url, description.ifBlank { null }, isPublic.toBoolean()) }.getOrElse { throw Exception("Could not update station.") }
            if (app.core.player.state.value.radioStation?.id == station.id) {
                stations.byId(station.id)?.let(app.core.player::refreshRadioStation)
            }
            app.messages.show("Station updated")
        }
    }
}

/** A station's long-press menu, with its Edit sheet and Delete confirmation. */
@Composable
fun RadioStationMenuSheet(station: RadioStation, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val actions = remember { EntityActions(app) }
    var shown by remember { mutableStateOf<String?>(null) }
    when (shown) {
        "edit" -> RadioStationFormSheet(station, onDismiss)
        "delete" -> RadioStationDeletion(station, onDismiss) { actions.delete(station) }
        else -> ActionsSheet(onDismiss, actions.stationMenu(station, onEdit = { shown = "edit" }, onDelete = { shown = "delete" })) {
            PreviewCard(station.logo, station.name, station.description)
        }
    }
}

@Composable
fun RadioStationDeletion(station: RadioStation, onDismiss: () -> Unit, onDelete: () -> Unit) {
    ConfirmDialog(
        title = "Delete station?",
        message = "Delete “${station.name}”? This cannot be undone.",
        confirmLabel = "Delete",
        onDismiss = onDismiss,
        onConfirm = onDelete,
    )
}
