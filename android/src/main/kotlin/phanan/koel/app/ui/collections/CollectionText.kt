package phanan.koel.app.ui.collections

import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Playlist

/** Whether "Go to Artist" makes sense: not for the catch-all Unknown and Various artists. */
val Album.hasBrowsableArtist: Boolean
    get() = artistName != "Unknown Artist" && artistName != "Various Artists"

val Playlist.kindLabel: String
    get() = if (isSmart) "Smart playlist" else "Standard playlist"

object YearInput {
    /** Keeps only digits, at most four of them. */
    fun sanitized(text: String): String = text.filter { it in '0'..'9' }.take(4)

    fun value(text: String): Int? = sanitized(text).toIntOrNull()
}

/** HTML from the server as plain paragraphs, like iOS's `plainText`. */
val String.plainText: String
    get() = replace(Regex("<br\\s*/?>|</p>", RegexOption.IGNORE_CASE), "\n")
        .replace(Regex("<[^>]+>"), "")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replace(Regex("\n{3,}"), "\n\n")
        .trim()
