package phanan.koel.shared.util

data class LyricLine(val time: Double, val text: String)

data class LyricLineLook(val opacity: Double, val blur: Double, val scale: Double)

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

    /** Lines fade, blur and shrink the further they are from the one being sung; all look alike while the song isn't playing. */
    fun lineLook(index: Int, currentIndex: Int): LyricLineLook {
        if (currentIndex < 0) return idleLook
        val distance = minOf(kotlin.math.abs(index - currentIndex), opacityByDistance.lastIndex)
        return LyricLineLook(
            opacity = opacityByDistance[distance],
            blur = blurByDistance[distance],
            scale = if (distance == 0) 1.0 else 0.96,
        )
    }

    private val opacityByDistance = listOf(1.0, 0.55, 0.35, 0.22, 0.12)
    private val blurByDistance = listOf(0.0, 0.5, 1.5, 2.5, 3.5)
    private val idleLook = LyricLineLook(opacity = 0.3, blur = 0.0, scale = 1.0)

    private fun MatchResult.seconds(): Double {
        val (minutes, seconds, fraction) = destructured
        val fractionSeconds = fraction.toInt() / if (fraction.length == 3) 1000.0 else 100.0
        return minutes.toInt() * 60 + seconds.toInt() + fractionSeconds
    }
}
