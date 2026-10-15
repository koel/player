package phanan.koel.shared.json

import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull

internal val KoelJson = Json {
    ignoreUnknownKeys = true
    isLenient = true
    coerceInputValues = true
    explicitNulls = false
    encodeDefaults = true
}

private fun Decoder.primitiveOrNull(): JsonPrimitive? =
    (this as JsonDecoder).decodeJsonElement() as? JsonPrimitive

/** Older servers send numeric IDs; newer ones send strings. */
internal object FlexibleStringSerializer : KSerializer<String> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("FlexibleString", PrimitiveKind.STRING)
    override fun deserialize(decoder: Decoder): String = decoder.primitiveOrNull()?.content.orEmpty()
    override fun serialize(encoder: Encoder, value: String) = encoder.encodeString(value)
}

/** Years and similar fields arrive as numbers or numeric strings. */
internal object FlexibleIntSerializer : KSerializer<Int?> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("FlexibleInt", PrimitiveKind.INT)

    override fun deserialize(decoder: Decoder): Int? {
        val primitive = decoder.primitiveOrNull() ?: return null
        if (primitive is JsonNull) return null
        return primitive.intOrNull ?: primitive.doubleOrNull?.toInt() ?: primitive.content.toIntOrNull()
    }

    override fun serialize(encoder: Encoder, value: Int?) {
        if (value == null) encoder.encodeNull() else encoder.encodeInt(value)
    }
}

/** Older servers send booleans as 0/1. */
internal object FlexibleBooleanSerializer : KSerializer<Boolean> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("FlexibleBoolean", PrimitiveKind.BOOLEAN)

    override fun deserialize(decoder: Decoder): Boolean {
        val primitive = decoder.primitiveOrNull() ?: return false
        return primitive.booleanOrNull ?: ((primitive.doubleOrNull ?: 0.0) != 0.0)
    }

    override fun serialize(encoder: Encoder, value: Boolean) = encoder.encodeBoolean(value)
}

/** PHP encodes an empty associative array as `[]`. */
internal object FlexibleProgressMapSerializer : KSerializer<Map<String, Double>> {
    private val delegate = MapSerializer(String.serializer(), Double.serializer())
    override val descriptor: SerialDescriptor = delegate.descriptor

    override fun deserialize(decoder: Decoder): Map<String, Double> {
        val element = (decoder as JsonDecoder).decodeJsonElement()
        if (element !is JsonObject) return emptyMap()
        return element.mapNotNull { (key, value) -> (value as? JsonPrimitive)?.doubleOrNull?.let { key to it } }.toMap()
    }

    override fun serialize(encoder: Encoder, value: Map<String, Double>) = delegate.serialize(encoder, value)
}

internal fun JsonArray.objects(): List<JsonObject> = filterIsInstance<JsonObject>()
