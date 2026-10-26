package phanan.koel.shared.session

data class ServerInfo(
    val version: SemanticVersion,
    val cdnUrl: String?,
    val transcoding: Boolean,
    val useLastFm: Boolean,
    val songCount: Int,
    val koelPlus: Boolean = false,
) {
    fun supports(feature: Feature): Boolean = version >= feature.minimumVersion
}

enum class Feature(internal val minimumVersion: SemanticVersion) {
    PODCASTS(SemanticVersion(7, 0, 0)),
    QUEUE_STATE_SYNC(SemanticVersion(6, 11, 6)),
    RADIO_STATIONS(SemanticVersion(7, 13, 0)),
    FAVORITE_ENTITIES(SemanticVersion(7, 11, 0)),
    CUSTOM_PLAYLIST_ORDER(SemanticVersion(7, 0, 2)),
    CUSTOM_FAVORITES_ORDER(SemanticVersion(9, 0, 0)),
}

data class SemanticVersion(val major: Int, val minor: Int, val patch: Int) : Comparable<SemanticVersion> {
    override fun compareTo(other: SemanticVersion): Int =
        compareValuesBy(this, other, { it.major }, { it.minor }, { it.patch })

    companion object {
        /** Accepts "v7.2.1", "7.2" and suffixed builds like "8.0.0-beta". */
        fun parse(raw: String): SemanticVersion {
            val parts = raw.trim().removePrefix("v").substringBefore('-').split('.')
            fun part(index: Int) = parts.getOrNull(index)?.toIntOrNull() ?: 0
            return SemanticVersion(part(0), part(1), part(2))
        }
    }
}
