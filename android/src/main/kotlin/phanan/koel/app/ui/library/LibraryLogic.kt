package phanan.koel.app.ui.library

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import phanan.koel.shared.models.PodcastSortField
import java.net.URI

class IndexedSection<T>(val letter: String, val items: List<T>)

/** Groups name-sorted lists by first letter for the side index, as Flutter's alphabet scrollbar did. */
object SectionIndex {
    const val MINIMUM_ITEM_COUNT = 100

    fun isShown(itemCount: Int, isSortedByName: Boolean) = isSortedByName && itemCount >= MINIMUM_ITEM_COUNT

    /** "A" to "Z" for names starting with a Latin letter, "#" for anything else. */
    fun letter(name: String): String {
        val first = name.firstOrNull() ?: return "#"
        return if (first in 'a'..'z' || first in 'A'..'Z') first.uppercase() else "#"
    }

    /** Keeps the list's order: each letter's section sits where its first item appeared. */
    fun <T> sections(items: List<T>, name: (T) -> String): List<IndexedSection<T>> {
        val grouped = LinkedHashMap<String, MutableList<T>>()
        items.forEach { grouped.getOrPut(letter(name(it))) { mutableListOf() }.add(it) }
        return grouped.map { (letter, members) -> IndexedSection(letter, members) }
    }

    /** Where each letter's first item sits in [items]. */
    fun <T> firstPositions(items: List<T>, name: (T) -> String): Map<String, Int> {
        val positions = LinkedHashMap<String, Int>()
        items.forEachIndexed { index, item -> positions.putIfAbsent(letter(name(item)), index) }
        return positions
    }
}

/** An http or https address with a host, as podcast feeds and radio streams need. */
val String.isWebUrl: Boolean
    get() {
        val uri = runCatching { URI(trim()) }.getOrNull() ?: return false
        val scheme = uri.scheme?.lowercase() ?: return false
        return (scheme == "http" || scheme == "https") && !uri.host.isNullOrBlank()
    }

/** The ways Podcasts can be sorted, in iOS's order. */
enum class PodcastSortOption(val label: String, val field: PodcastSortField) {
    LastPlayed("Last played", PodcastSortField.LAST_PLAYED_AT),
    Subscribed("Subscribed", PodcastSortField.SUBSCRIBED_AT),
    Title("Title", PodcastSortField.TITLE),
    Author("Author", PodcastSortField.AUTHOR);

    companion object {
        fun named(name: String) = entries.firstOrNull { it.name == name } ?: LastPlayed
    }
}

/** The message for a failed podcast subscription; 409 means the user already follows the feed. */
fun podcastAddFailureMessage(statusCode: Int?) =
    if (statusCode == 409) "You are already subscribed to this podcast." else "Something wrong happened. Please try again."

/** The Albums screen's card grid, for places that can't use a lazy grid. */
object AlbumGrid {
    val minimumCardWidth = 150.dp
    val spacing = 16.dp
    val rowSpacing = 20.dp

    fun columnCount(availableWidth: Dp): Int = maxOf(1, ((availableWidth + spacing) / (minimumCardWidth + spacing)).toInt())
}
