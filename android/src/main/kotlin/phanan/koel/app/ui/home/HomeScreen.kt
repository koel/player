package phanan.koel.app.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.outlined.DownloadForOffline
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.AppSheet
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.player.PlaybackSettingsEntry
import phanan.koel.app.ui.components.Artwork
import phanan.koel.app.ui.components.ArtworkCard
import phanan.koel.app.ui.components.ConfirmDialog
import phanan.koel.app.ui.components.ListPlaceholder
import phanan.koel.app.ui.components.MenuAction
import phanan.koel.app.ui.components.MenuItems
import phanan.koel.app.ui.components.RefreshableListScaffold
import phanan.koel.app.ui.components.SectionSpacing
import phanan.koel.app.ui.components.PlayableRow
import phanan.koel.app.ui.components.Shelf
import phanan.koel.app.ui.components.rememberLoading
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.library.AlbumMenuSheet
import phanan.koel.app.ui.library.ArtistMenuSheet
import phanan.koel.app.ui.library.RemoveAllDownloadsConfirmation
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Artist
import phanan.koel.shared.models.Playable

@Composable
fun HomeScreen() {
    val app = LocalAppModel.current
    val overview = app.core.overview
    val user by app.core.auth.currentUser.collectAsStateWithLifecycle()
    val recentlyPlayed by app.core.recentlyPlayed.items.collectAsStateWithLifecycle()
    val blocks = HomeBlock.ordered(user?.preferences?.homeBlocksOrder.orEmpty())
    val blockItems = blocks.associateWith { block -> block.items(overview).collectAsStateWithLifecycle().value }
    val isEmpty = recentlyPlayed.isEmpty() && blockItems.values.all { it.isEmpty() }
    val loading = rememberLoading { forceRefresh ->
        runCatching { overview.refresh() }
            .onFailure { if (forceRefresh && !isEmpty) app.messages.showError() }
            .getOrThrow()
    }

    RefreshableListScaffold(
        title = "Home",
        loading = loading,
        isEmpty = isEmpty,
        placeholder = {
            ListPlaceholder(
                loading,
                emptyTitle = "No activities… yet",
                emptyIcon = Icons.Default.MusicNote,
                emptyDescription = "Pull down to refresh this screen.",
            )
        },
        actions = {
            IconButton(onClick = { app.navigator.push(Route.RecentlyPlayed) }) {
                Icon(Icons.Outlined.Schedule, contentDescription = "Recently Played")
            }
            ProfileMenu()
        },
    ) { topPadding ->
        LazyColumn(
            contentPadding = PaddingValues(top = topPadding + 8.dp, bottom = ScreenBottomPadding),
            verticalArrangement = Arrangement.spacedBy(SectionSpacing),
        ) {
            if (recentlyPlayed.isNotEmpty()) {
                item(key = "recent") {
                    Column { recentlyPlayed.take(4).forEach { PlayableRow(it, hasQueueSwipes = false) } }
                }
            }
            blocks.forEach { block ->
                val items = blockItems.getValue(block)
                if (items.isNotEmpty()) item(key = block.name) { BlockShelf(block, items) }
            }
        }
    }
}

@Composable
internal fun BlockShelf(block: HomeBlock, items: List<Any>) {
    val app = LocalAppModel.current
    var albumMenu by remember { mutableStateOf<Album?>(null) }
    var artistMenu by remember { mutableStateOf<Artist?>(null) }

    albumMenu?.let { AlbumMenuSheet(it) { albumMenu = null } }
    artistMenu?.let { ArtistMenuSheet(it) { artistMenu = null } }

    Shelf(title = block.title, items = items, key = { it.hashCode() }, onShowAll = { app.navigator.push(block.seeAll) }) { item ->
        when (item) {
            is Playable -> ArtworkCard(item.artworkUrl, item.title, subtitle = item.subtitle, onLongClick = { app.sheet = AppSheet.Actions(item) }) {
                app.actions.play(item)
            }
            is Album -> ArtworkCard(item.cover, item.name, subtitle = item.artistName, onLongClick = { albumMenu = item }) {
                app.navigator.push(Route.Album(item.id))
            }
            is Artist -> ArtworkCard(item.imageUrl, item.name, isCircular = true, onLongClick = { artistMenu = item }) {
                app.navigator.push(Route.Artist(item.id))
            }
        }
    }
}

/** The avatar on Home: who is logged in, Playback Settings, Remove All Downloads and Log out. */
@Composable
private fun ProfileMenu() {
    val app = LocalAppModel.current
    val user by app.core.auth.currentUser.collectAsStateWithLifecycle()
    val downloaded by app.core.downloads.downloadedIds.collectAsStateWithLifecycle()
    var isOpen by rememberSaveable { mutableStateOf(false) }
    var isConfirmingLogOut by rememberSaveable { mutableStateOf(false) }
    var isConfirmingRemoveDownloads by rememberSaveable { mutableStateOf(false) }

    Box {
        IconButton(onClick = { isOpen = true }) {
            val avatar = user?.avatar
            if (avatar.isNullOrBlank()) {
                Icon(Icons.Default.AccountCircle, contentDescription = "Profile")
            } else {
                Artwork(avatar, size = 30.dp, isCircle = true)
            }
        }
        DropdownMenu(expanded = isOpen, onDismissRequest = { isOpen = false }) {
            user?.let {
                Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Text(it.name, style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.SemiBold), color = KoelColors.secondaryText)
                    Text(it.email, style = MaterialTheme.typography.labelMedium, color = KoelColors.secondaryText)
                }
                HorizontalDivider(color = KoelColors.hairline)
            }
            MenuItems(
                listOf(
                    MenuAction(PlaybackSettingsEntry.LABEL, PlaybackSettingsEntry.icon) { app.sheet = AppSheet.PlaybackSettings },
                    MenuAction("Remove all downloads", Icons.Outlined.DownloadForOffline, isDestructive = true, isEnabled = downloaded.isNotEmpty(), startsSection = true) {
                        isConfirmingRemoveDownloads = true
                    },
                    MenuAction("Log out", Icons.AutoMirrored.Filled.Logout, isDestructive = true) { isConfirmingLogOut = true },
                ),
            ) { isOpen = false }
        }
    }

    if (isConfirmingLogOut) {
        ConfirmDialog(title = "Log out?", confirmLabel = "Confirm", onDismiss = { isConfirmingLogOut = false }) {
            app.logOut()
        }
    }
    if (isConfirmingRemoveDownloads) RemoveAllDownloadsConfirmation { isConfirmingRemoveDownloads = false }
}
