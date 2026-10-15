package phanan.koel.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import phanan.koel.shared.json.FlexibleBooleanSerializer
import phanan.koel.shared.json.FlexibleIntSerializer
import phanan.koel.shared.json.FlexibleProgressMapSerializer
import phanan.koel.shared.json.FlexibleStringSerializer

@Serializable
data class Album(
    @Serializable(FlexibleStringSerializer::class) val id: String,
    val name: String,
    val cover: String? = null,
    @SerialName("artist_id") @Serializable(FlexibleStringSerializer::class) val artistId: String = "",
    @SerialName("artist_name") val artistName: String = "",
    @Serializable(FlexibleIntSerializer::class) val year: Int? = null,
    @Serializable(FlexibleBooleanSerializer::class) val favorite: Boolean = false,
    val permissions: Permissions = Permissions(),
) {
    val canEdit: Boolean get() = permissions.edit
    val isUnknown: Boolean get() = name == "Unknown Album"
}

@Serializable
data class Artist(
    @Serializable(FlexibleStringSerializer::class) val id: String,
    val name: String,
    @SerialName("image") val imageUrl: String? = null,
    @Serializable(FlexibleBooleanSerializer::class) val favorite: Boolean = false,
    val permissions: Permissions = Permissions(),
) {
    val canEdit: Boolean get() = permissions.edit
    val isUnknown: Boolean get() = name == "Unknown Artist"
    val isVarious: Boolean get() = name == "Various Artists"
    val isStandard: Boolean get() = !isUnknown && !isVarious
}

@Serializable
data class Genre(
    @Serializable(FlexibleStringSerializer::class) val id: String,
    val name: String = "",
    @SerialName("song_count") val songCount: Int = 0,
    val length: Double = 0.0,
)

@Serializable
data class Playlist(
    @Serializable(FlexibleStringSerializer::class) val id: String,
    val name: String,
    @SerialName("is_smart") val isSmart: Boolean = false,
    @SerialName("folder_id") val folderId: String? = null,
    val description: String? = null,
    val cover: String? = null,
    val permissions: Permissions = Permissions(),
) {
    val canEdit: Boolean get() = permissions.edit
    val canDelete: Boolean get() = permissions.delete
}

@Serializable
data class PlaylistFolder(
    val id: String,
    val name: String,
)

@Serializable
data class Podcast(
    val id: String,
    val title: String,
    val url: String = "",
    val link: String = "",
    val description: String = "",
    val author: String = "",
    @SerialName("image") val imageUrl: String = "",
    @SerialName("subscribed_at") val subscribedAt: String = "",
    @SerialName("last_played_at") val lastPlayedAt: String = "",
    val state: PodcastState = PodcastState(),
    @Serializable(FlexibleBooleanSerializer::class) val favorite: Boolean = false,
)

@Serializable
data class PodcastState(
    @SerialName("current_episode") val currentEpisodeId: String? = null,
    @Serializable(FlexibleProgressMapSerializer::class)
    val progresses: Map<String, Double> = emptyMap(),
)

@Serializable
data class RadioStation(
    val id: String,
    val name: String,
    val url: String,
    val logo: String? = null,
    val description: String? = null,
    @SerialName("is_public") val isPublic: Boolean = false,
    @Serializable(FlexibleBooleanSerializer::class) val favorite: Boolean = false,
    val permissions: Permissions = Permissions(),
) {
    val canEdit: Boolean get() = permissions.edit
    val canDelete: Boolean get() = permissions.delete
}

@Serializable
data class User(
    @Serializable(FlexibleStringSerializer::class) val id: String,
    val name: String,
    val email: String,
    val avatar: String? = null,
    val preferences: UserPreferences = UserPreferences(),
)

@Serializable
data class UserPreferences(
    @SerialName("home_blocks_order") val homeBlocksOrder: List<String> = emptyList(),
)
