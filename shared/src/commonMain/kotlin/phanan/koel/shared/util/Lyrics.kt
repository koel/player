package phanan.koel.shared.util

data class LyricLine(val time: Double, val text: String)

/** Time-synced lyrics in LRC format: lines like `[01:02.34]Text`, possibly with several tags. */
object Lyrics {
    private val timeTag = Regex("""\[(\d{1,2}):(\d{2})\.(\d{2,3})]""")

    fun isSynced(lyrics: String): Boolean = timeTag.containsMatchIn(lyrics)

    fun parseSynced(lyrics: String): List<LyricLine> =
        lyrics.lineSequence()
            .flatMap { line ->
                val tags = timeTag.findAll(line).toList()
                val text = tags.lastOrNull()?.let { line.substring(it.range.last + 1).trim() }.orEmpty()
                if (text.isEmpty()) emptyList() else tags.map { LyricLine(it.seconds(), text) }
            }
            .sortedBy(LyricLine::time)
            .toList()

    /** The index of the line being sung at [position], or -1 before the first line. */
    fun currentLineIndex(lines: List<LyricLine>, position: Double): Int =
        lines.indexOfLast { position >= it.time }

    private fun MatchResult.seconds(): Double {
        val (minutes, seconds, fraction) = destructured
        val fractionSeconds = fraction.toInt() / if (fraction.length == 3) 1000.0 else 100.0
        return minutes.toInt() * 60 + seconds.toInt() + fractionSeconds
    }
}
