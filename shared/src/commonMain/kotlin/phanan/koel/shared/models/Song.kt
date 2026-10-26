package phanan.koel.shared.models

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KeepGeneratedSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonTransformingSerializer
import kotlinx.serialization.json.jsonObject
import phanan.koel.shared.json.FlexibleBooleanSerializer
import phanan.koel.shared.json.FlexibleIntSerializer
import phanan.koel.shared.json.FlexibleStringSerializer

@OptIn(ExperimentalSerializationApi::class)
@Serializable(with = SongSerializer::class)
@KeepGeneratedSerializer
data class Song(
    override val id: String,
    override val title: String,
    val lyrics: String = "",
    override val length: Double = 0.0,
    @SerialName("album_id") @Serializable(FlexibleStringSerializer::class) val albumId: String = "",
    @SerialName("album_name") val albumName: String = "",
    @SerialName("artist_id") @Serializable(FlexibleStringSerializer::class) val artistId: String = "",
    @SerialName("artist_name") val artistName: String = "",
    @SerialName("album_artist_id") @Serializable(FlexibleStringSerializer::class) val albumArtistId: String = "",
    @SerialName("album_artist_name") val albumArtistName: String = "",
    @SerialName("album_cover") val albumCover: String? = null,
    val track: Int = 0,
    val disc: Int = 1,
    @Serializable(FlexibleIntSerializer::class) val year: Int? = null,
    val genre: String = "",
    @Serializable(FlexibleBooleanSerializer::class) override val favorite: Boolean = false,
    @SerialName("play_count") override val playCount: Int = 0,
    @SerialName("created_at") override val createdAt: String = "",
    val type: String = "songs",
    /** Integrated loudness in LUFS, from Koel Plus's audio analysis. */
    val loudness: Double? = null,
    /** In dBTP, from Koel Plus's audio analysis. */
    @SerialName("true_peak") val truePeak: Double? = null,
) : Playable {
    override val artworkUrl: String? get() = albumCover
    override val subtitle: String get() = artistName
    override val collectionName: String get() = albumName

    override fun withFavorite(favorite: Boolean): Song = copy(favorite = favorite)
    override fun withPlayCount(playCount: Int): Song = copy(playCount = playCount)
}

/** `liked` is the legacy name for `favorite`; when both are present, `favorite` wins. */
internal object SongSerializer : JsonTransformingSerializer<Song>(Song.generatedSerializer()) {
    override fun transformDeserialize(element: JsonElement): JsonElement {
        val json = element.jsonObject
        val favorite = json["favorite"]?.takeUnless { it is JsonNull } ?: json["liked"] ?: return json
        return JsonObject(json + ("favorite" to favorite))
    }
}
