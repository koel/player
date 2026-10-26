package phanan.koel.shared.models

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNames
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
    val rules: JsonElement? = null,
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
    @SerialName("homepage_url") val homepageUrl: String? = null,
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
    val abilities: List<String> = emptyList(),
) {
    val canManageRadioStations: Boolean get() = MANAGE_RADIO_STATIONS in abilities
}

private const val MANAGE_RADIO_STATIONS = "manage radio stations"

@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class UserPreferences(
    @SerialName("home_blocks_order") val homeBlocksOrder: List<String> = emptyList(),
    @SerialName("current_equalizer_preset") @JsonNames("equalizer") val equalizer: EqualizerPreset? = null,
    /** Absent on servers that can't save presets yet. */
    @SerialName("equalizer_presets") val equalizerPresets: List<EqualizerPreset>? = null,
    @SerialName("crossfade_duration") val crossfadeDuration: Int? = null,
    @SerialName("normalize_volume") val normalizeVolume: Boolean? = null,
)
