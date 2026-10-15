package phanan.koel.shared.models

enum class PodcastSortField {
    LAST_PLAYED_AT,
    SUBSCRIBED_AT,
    TITLE,
    AUTHOR,
}

fun List<Podcast>.sorted(field: PodcastSortField, order: SortOrder): List<Podcast> {
    val key: (Podcast) -> String = when (field) {
        PodcastSortField.LAST_PLAYED_AT -> Podcast::lastPlayedAt
        PodcastSortField.SUBSCRIBED_AT -> Podcast::subscribedAt
        PodcastSortField.TITLE -> Podcast::title
        PodcastSortField.AUTHOR -> Podcast::author
    }
    return if (order == SortOrder.ASC) sortedBy(key) else sortedByDescending(key)
}
