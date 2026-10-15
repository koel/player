package phanan.koel.shared.models

import kotlinx.serialization.Serializable

/** Missing on servers older than 9.2.0, which hides edit/delete actions. */
@Serializable
data class Permissions(
    val edit: Boolean = false,
    val delete: Boolean = false,
)
