package phanan.koel.shared.session

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import phanan.koel.shared.models.Episode
import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.RadioStation
import phanan.koel.shared.models.Song
import phanan.koel.shared.storage.Preferences

/** Server facts learned from `GET /data`; null until the app has loaded them. */
class Session(private val preferences: Preferences) {
    private val serverInfoState = MutableStateFlow<ServerInfo?>(null)
    val serverInfo: StateFlow<ServerInfo?> = serverInfoState.asStateFlow()

    fun supports(feature: Feature): Boolean = serverInfo.value?.supports(feature) ?: false

    internal fun update(info: ServerInfo?) {
        serverInfoState.value = info
    }

    private val mediaHost: String
        get() = (serverInfo.value?.cdnUrl?.takeIf { it.isNotBlank() } ?: preferences.host.orEmpty()).trimEnd('/')

    fun sourceUrl(playable: Playable): String {
        val token = preferences.audioToken.orEmpty()
        return when (playable) {
            is Song -> if (serverInfo.value?.transcoding == true) {
                "$mediaHost/play/${playable.id}/1/128?t=$token"
            } else {
                "$mediaHost/play/${playable.id}?t=$token"
            }
            is Episode -> "$mediaHost/play/${playable.id}?t=$token"
        }
    }

    fun radioStreamUrl(station: RadioStation): String =
        "${preferences.host.orEmpty()}/radio/stream/${station.id}?t=${preferences.audioToken.orEmpty()}"
}
