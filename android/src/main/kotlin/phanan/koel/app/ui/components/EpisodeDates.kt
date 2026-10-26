package phanan.koel.app.ui.components

import java.time.Duration
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

/** An episode's date the way iOS lists it: relative while recent, the date itself after half a year. */
object EpisodeDates {
    private const val RELATIVE_LIMIT_DAYS = 180L

    fun label(createdAt: String, now: Instant, zone: ZoneId = ZoneId.systemDefault(), locale: Locale = Locale.getDefault()): String? {
        val date = parse(createdAt) ?: return null
        val days = Duration.between(date, now).toDays()
        if (days > RELATIVE_LIMIT_DAYS) {
            return DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(locale).format(date.atZone(zone))
        }
        return when {
            days < 1 -> "today"
            days < 2 -> "yesterday"
            days < 7 -> "$days days ago"
            days < 14 -> "last week"
            days < 30 -> "${days / 7} weeks ago"
            days < 60 -> "last month"
            else -> "${days / 30} months ago"
        }
    }

    private fun parse(value: String): Instant? =
        runCatching { OffsetDateTime.parse(value).toInstant() }.getOrNull()
            ?: runCatching { Instant.parse(value) }.getOrNull()
}
