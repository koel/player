package phanan.koel.shared.models

import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonContentPolymorphicSerializer
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

@Serializable(with = PlayableSerializer::class)
sealed interface Playable {
    val id: String
    val title: String
    val length: Double
    val createdAt: String
    val favorite: Boolean
    val playCount: Int
    val artworkUrl: String?

    /** Artist for songs, podcast author for episodes. */
    val subtitle: String

    /** Album for songs, podcast title for episodes. */
    val collectionName: String

    fun withFavorite(favorite: Boolean): Playable
    fun withPlayCount(playCount: Int): Playable
}

internal object PlayableSerializer : JsonContentPolymorphicSerializer<Playable>(Playable::class) {
    override fun selectDeserializer(element: JsonElement): DeserializationStrategy<Playable> =
        if (element.jsonObject["type"]?.jsonPrimitive?.content == "episodes") Episode.serializer() else Song.serializer()
}

fun Playable.matches(keywords: String): Boolean {
    val needle = keywords.lowercase()
    return title.lowercase().contains(needle) ||
        subtitle.lowercase().contains(needle) ||
        collectionName.lowercase().contains(needle)
}
