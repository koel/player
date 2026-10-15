package phanan.koel.shared.stores

import phanan.koel.shared.onMain
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import phanan.koel.shared.api.ApiClient
import phanan.koel.shared.json.KoelJson
import phanan.koel.shared.models.RadioStation

class RadioStationStore internal constructor(private val api: ApiClient) {
    internal val vault = Vault<RadioStation> { it.id }
    private val list = vault.liveList()

    val stations: StateFlow<List<RadioStation>> = list.items

    fun byId(id: String): RadioStation? = vault[id]

    @Throws(Exception::class)
    suspend fun fetchAll(): Unit = onMain {
        list.ids = vault.sync(api.getList("radio/stations", RadioStation.serializer())).map(RadioStation::id)
    }

    @Throws(Exception::class)
    suspend fun create(name: String, url: String, description: String? = null, isPublic: Boolean = false): RadioStation = onMain {
        val json = api.post("radio/stations", buildJsonObject {
            put("name", name)
            put("url", url)
            put("is_public", isPublic)
            if (!description.isNullOrEmpty()) put("description", description)
        })

        val station = vault.sync(KoelJson.decodeFromJsonElement(RadioStation.serializer(), json))
        list.append(listOf(station.id))
        station
    }

    @Throws(Exception::class)
    suspend fun update(
        station: RadioStation,
        name: String,
        url: String,
        description: String? = null,
        isPublic: Boolean = false,
    ): Unit = onMain {
        api.put("radio/stations/${station.id}", buildJsonObject {
            put("name", name)
            put("url", url)
            put("description", description.orEmpty())
            put("is_public", isPublic)
        })

        vault.update(station.id) { it.copy(name = name, url = url, description = description, isPublic = isPublic) }
    }

    /** Removes the station right away, and puts it back if the server refuses. */
    @Throws(Exception::class)
    suspend fun remove(station: RadioStation): Unit = onMain {
        val index = list.ids.indexOf(station.id).coerceAtLeast(0)
        list.remove(station.id)

        try {
            api.delete("radio/stations/${station.id}")
        } catch (error: Exception) {
            list.insert(index, station.id)
            throw error
        }

        vault.remove(station.id)
    }

    @Throws(Exception::class)
    suspend fun toggleFavorite(station: RadioStation): Unit = onMain {
        val wasFavorite = vault[station.id]?.favorite ?: station.favorite
        vault.update(station.id) { it.copy(favorite = !wasFavorite) }

        try {
            api.post("favorites/toggle", buildJsonObject {
                put("type", "radio-station")
                put("id", station.id)
            })
        } catch (error: Exception) {
            vault.update(station.id) { it.copy(favorite = wasFavorite) }
            throw error
        }
    }

    /** The title the station is broadcasting right now, if it reports one. */
    @Throws(Exception::class)
    suspend fun nowPlaying(station: RadioStation): String? = onMain {
        val response = api.get("radio/stations/${station.id}/now-playing") as? JsonObject
        response?.get("stream_title")?.jsonPrimitive?.contentOrNull
    }

    internal fun reset() {
        list.ids = emptyList()
        vault.clear()
    }
}
