package phanan.koel.shared.json

import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull

internal fun JsonObject.string(key: String): String? = (get(key) as? JsonPrimitive)?.contentOrNull

/** Accepts numbers and numeric strings, as the server sends both. */
internal fun JsonObject.int(key: String): Int? {
    val primitive = get(key) as? JsonPrimitive ?: return null
    return primitive.doubleOrNull?.toInt() ?: primitive.contentOrNull?.toIntOrNull()
}

internal fun JsonObject.obj(key: String): JsonObject? = get(key) as? JsonObject

/** Empty when the key is missing or null, as on servers that predate it. */
internal fun <T> JsonObject.decodeList(key: String, serializer: KSerializer<T>): List<T> =
    KoelJson.decodeFromJsonElement(ListSerializer(serializer), get(key) as? JsonArray ?: JsonArray(emptyList()))
