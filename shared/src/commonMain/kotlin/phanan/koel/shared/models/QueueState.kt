package phanan.koel.shared.models

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import phanan.koel.shared.stores.PlayableStore

/** The queue the server remembers from the user's last session, from `/data`'s `queue_state`. */
data class QueueState(
    val playables: List<Playable>,
    val currentPlayable: Playable?,
    val playbackPosition: Double,
) {
    companion object {
        val EMPTY = QueueState(emptyList(), null, 0.0)

        internal fun parse(json: JsonElement, playables: PlayableStore): QueueState {
            val root = json.jsonObject
            val queued = root["songs"]?.let { playables.sync(it) }.orEmpty()
            val current = root["current_song"]
                ?.takeUnless { it is JsonNull }
                ?.let { runCatching { playables.sync(JsonArray(listOf(it))).first() }.getOrNull() }
            val position = root["playback_position"]?.jsonPrimitive?.doubleOrNull ?: 0.0

            return QueueState(queued, current, position)
        }
    }
}
