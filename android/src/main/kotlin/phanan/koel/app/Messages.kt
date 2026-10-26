package phanan.koel.app

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.ui.graphics.vector.ImageVector
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlin.time.Duration.Companion.seconds

/** Brief confirmations such as "Queued", and errors, as Flutter's message overlay showed them. */
class Messages {
    data class Toast(val caption: String, val message: String?, val icon: ImageVector)

    private val flow = MutableSharedFlow<Toast>(extraBufferCapacity = 4, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    val all: SharedFlow<Toast> = flow.asSharedFlow()

    fun show(caption: String, message: String? = null, icon: ImageVector = Icons.Filled.CheckCircle) {
        flow.tryEmit(Toast(caption, message, icon))
    }

    fun showError(caption: String = "Error", message: String? = null) = show(caption, message, Icons.Default.WarningAmber)

    companion object {
        val duration = 2.seconds
    }
}
