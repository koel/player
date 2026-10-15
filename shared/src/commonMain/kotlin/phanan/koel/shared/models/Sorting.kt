package phanan.koel.shared.models

enum class SortOrder(val value: String) {
    ASC("asc"),
    DESC("desc"),
    ;

    fun toggled(): SortOrder = if (this == ASC) DESC else ASC
}

/** Sort fields the server and the local sorter both understand. */
object PlayableSortField {
    const val TITLE = "title"
    const val ALBUM_NAME = "album_name"
    const val ARTIST_NAME = "artist_name"
    const val CREATED_AT = "created_at"
    const val TRACK = "track"

    /** The order the server returned, e.g. a playlist's own order. */
    const val POSITION = "position"
}

object AlbumSortField {
    const val NAME = "name"
    const val ARTIST_NAME = "artist_name"
    const val YEAR = "year"
    const val CREATED_AT = "created_at"
}

object ArtistSortField {
    const val NAME = "name"
    const val CREATED_AT = "created_at"
}

fun List<Playable>.filtered(keywords: String): List<Playable> =
    if (keywords.isBlank()) this else filter { it.matches(keywords.trim()) }

fun List<Playable>.sorted(field: String, order: SortOrder): List<Playable> {
    if (field == PlayableSortField.POSITION) return if (order == SortOrder.ASC) this else reversed()

    val ascending = sortedWith(compareBy { it.sortKey(field) })
    return if (order == SortOrder.ASC) ascending else ascending.reversed()
}

private fun Playable.sortKey(field: String): String = when (this) {
    is Song -> {
        val discTrack = "${disc.toString().padStart(6, '0')}${track.toString().padStart(6, '0')}"
        when (field) {
            PlayableSortField.TITLE -> title
            PlayableSortField.ALBUM_NAME -> "$albumName$albumId$discTrack"
            PlayableSortField.ARTIST_NAME -> "$artistName$albumName$discTrack"
            PlayableSortField.CREATED_AT -> createdAt
            PlayableSortField.TRACK -> discTrack
            else -> ""
        }
    }
    is Episode -> when (field) {
        PlayableSortField.TITLE -> title
        PlayableSortField.ALBUM_NAME -> podcastTitle
        PlayableSortField.ARTIST_NAME -> podcastAuthor
        PlayableSortField.CREATED_AT -> createdAt
        else -> ""
    }
}
