package phanan.koel.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import phanan.koel.shared.json.FlexibleBooleanSerializer

@Serializable
data class Episode(
    override val id: String,
    override val title: String,
    override val length: Double = 0.0,
    @SerialName("podcast_id") val podcastId: String = "",
    @SerialName("podcast_title") val podcastTitle: String = "",
    @SerialName("podcast_author") val podcastAuthor: String = "",
    @SerialName("episode_description") val description: String = "",
    @SerialName("episode_image") val imageUrl: String? = null,
    @SerialName("episode_link") val link: String? = null,
    @Serializable(FlexibleBooleanSerializer::class) override val favorite: Boolean = false,
    @SerialName("play_count") override val playCount: Int = 0,
    @SerialName("created_at") override val createdAt: String = "",
    val type: String = "episodes",
) : Playable {
    override val artworkUrl: String? get() = imageUrl
    override val subtitle: String get() = podcastAuthor
    override val collectionName: String get() = podcastTitle

    override fun withFavorite(favorite: Boolean): Episode = copy(favorite = favorite)
    override fun withPlayCount(playCount: Int): Episode = copy(playCount = playCount)
}
