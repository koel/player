package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ViewList
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.vector.ImageVector
import phanan.koel.shared.models.AlbumSortField
import phanan.koel.shared.models.PlayableSortField
import phanan.koel.shared.models.SortOrder
import phanan.koel.shared.storage.KeyValueStore

data class SortOption(val field: String, val label: String)

data class SortSetting(val field: String, val order: SortOrder) {
    /** Picking a field sorts by it; picking the current field again flips the order. */
    fun picking(field: String): SortSetting = if (field == this.field) copy(order = order.toggled()) else SortSetting(field, SortOrder.ASC)

    /** Whether a list the server sorts and pages has to fetch its first page again to show this sort. */
    fun needsFirstPage(loaded: SortSetting, isEmpty: Boolean, forceRefresh: Boolean): Boolean = forceRefresh || isEmpty || loaded != this

    companion object {
        /** Where each list keeps its sort across launches. The app points it at its preferences on start. */
        lateinit var store: KeyValueStore

        fun remembered(key: String, default: SortSetting): SortSetting {
            val saved = store.get(storageKey(key)) ?: return default
            val order = SortOrder.entries.firstOrNull { it.value == saved.substringAfterLast(':') } ?: return default
            return SortSetting(saved.substringBeforeLast(':'), order)
        }

        fun remember(key: String, setting: SortSetting) {
            store.set(storageKey(key), "${setting.field}:${setting.order.value}")
        }

        private fun storageKey(key: String) = "sort.$key"
    }
}

/** Whether a collection list shows a grid of covers or rows, kept per list across launches like its sort. */
enum class CollectionLayout(val label: String, val icon: ImageVector) {
    Grid("Grid", Icons.Default.GridView),
    List("List", Icons.AutoMirrored.Filled.ViewList),
    ;

    companion object {
        fun remembered(key: String): CollectionLayout =
            SortSetting.store.get(storageKey(key))?.let { saved -> entries.firstOrNull { it.name == saved } } ?: Grid

        fun remember(key: String, layout: CollectionLayout) {
            SortSetting.store.set(storageKey(key), layout.name)
        }

        private fun storageKey(key: String) = "layout.$key"
    }
}

object SortOptions {
    private val title = SortOption(PlayableSortField.TITLE, "Title")
    private val artist = SortOption(PlayableSortField.ARTIST_NAME, "Artist")
    private val album = SortOption(PlayableSortField.ALBUM_NAME, "Album or podcast")
    private val track = SortOption(PlayableSortField.TRACK, "Track number")
    private val customOrder = SortOption(PlayableSortField.POSITION, "Custom order")
    private val recentlyAdded = SortOption(PlayableSortField.CREATED_AT, "Recently added")
    private val name = SortOption(AlbumSortField.NAME, "Name")
    private val year = SortOption(AlbumSortField.YEAR, "Year")

    val songs = listOf(title, artist, recentlyAdded)
    val albums = listOf(name, artist, year, recentlyAdded)
    val artists = listOf(name, recentlyAdded)
    val genreSongs = listOf(title, artist, album)
    val albumSongs = listOf(track, title, recentlyAdded)
    val artistSongs = listOf(title, album, recentlyAdded)
    val episodes = listOf(title, recentlyAdded)

    fun playlistSongs(supportsCustomOrder: Boolean) = (if (supportsCustomOrder) listOf(customOrder) else emptyList()) + listOf(title, artist, recentlyAdded)

    fun favorites(supportsCustomOrder: Boolean) = (if (supportsCustomOrder) listOf(customOrder) else emptyList()) + listOf(title, artist, recentlyAdded)
}

@Composable
fun SortMenu(
    options: List<SortOption>,
    setting: SortSetting,
    layout: CollectionLayout? = null,
    onLayoutChange: (CollectionLayout) -> Unit = {},
    onChange: (SortSetting) -> Unit,
) {
    var isOpen by remember { mutableStateOf(false) }

    Box {
        IconButton(onClick = { isOpen = true }) {
            Icon(Icons.Default.FilterList, contentDescription = "Sort")
        }
        DropdownMenu(expanded = isOpen, onDismissRequest = { isOpen = false }) {
            if (layout != null) {
                CollectionLayout.entries.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option.label) },
                        leadingIcon = { Icon(option.icon, contentDescription = null) },
                        trailingIcon = { if (option == layout) Icon(Icons.Default.Check, contentDescription = "Selected") },
                        onClick = {
                            isOpen = false
                            onLayoutChange(option)
                        },
                    )
                }
                HorizontalDivider()
            }
            options.forEach { option ->
                val isSelected = option.field == setting.field
                DropdownMenuItem(
                    text = { Text(option.label) },
                    trailingIcon = {
                        if (isSelected) {
                            Icon(
                                if (setting.order == SortOrder.ASC) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                                contentDescription = if (setting.order == SortOrder.ASC) "Ascending" else "Descending",
                            )
                        }
                    },
                    onClick = {
                        isOpen = false
                        onChange(setting.picking(option.field))
                    },
                )
            }
        }
    }
}

@Composable
fun rememberCollectionLayout(key: String): MutableState<CollectionLayout> {
    val state = remember(key) { mutableStateOf(CollectionLayout.remembered(key)) }
    LaunchedEffect(state.value) { CollectionLayout.remember(key, state.value) }
    return state
}

/** A list's sort, kept across visits for as long as the app runs. */
@Composable
fun rememberSortSetting(key: String, default: SortSetting): MutableState<SortSetting> {
    val state = remember(key) { mutableStateOf(SortSetting.remembered(key, default)) }
    LaunchedEffect(state.value) { SortSetting.remember(key, state.value) }
    return state
}
