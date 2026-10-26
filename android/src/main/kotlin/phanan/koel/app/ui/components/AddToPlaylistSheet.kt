package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.library.LibraryRow
import phanan.koel.app.ui.library.PlaceholderArtwork
import phanan.koel.app.ui.library.PlaylistFormSheet
import phanan.koel.app.ui.library.PlaylistRow
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.Playlist

/** Picks a standard playlist to add songs to, or creates a new one with them. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddToPlaylistSheet(playables: List<Playable>, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val playlists by app.core.playlists.standardPlaylists.collectAsStateWithLifecycle()
    var isNaming by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { runCatching { app.core.playlists.fetchAll() } }

    fun add(playlist: Playlist) {
        onDismiss()
        app.actions.addToPlaylist(playables, playlist)
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.navigationBarsPadding()) {
            SheetTitle("Add to a Playlist", Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
            LibraryRow(
                title = "New Playlist…",
                artwork = { PlaceholderArtwork(Icons.Default.Add, 44.dp) },
                showsChevron = false,
            ) { isNaming = true }
            LazyColumn {
                items(playlists.sortedBy { it.name.lowercase() }, key = { it.id }) { playlist ->
                    PlaylistRow(playlist) { add(playlist) }
                }
            }
        }
    }

    if (isNaming) PlaylistFormSheet(null, onDismiss = { isNaming = false }, onCreate = ::add)
}
