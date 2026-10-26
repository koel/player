package phanan.koel.app

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.WarningAmber
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.time.Duration.Companion.seconds

class MessagesTest {
    private val messages = Messages()

    private fun nextToast(post: () -> Unit): Messages.Toast = runBlocking {
        val toast = async(start = CoroutineStart.UNDISPATCHED) { messages.all.first() }
        post()
        toast.await()
    }

    @Test
    fun showsCaptionAndMessageWithTheDefaultCheckmark() {
        val toast = nextToast { messages.show("Queued", "To be played next.") }

        assertEquals(Messages.Toast("Queued", "To be played next.", Icons.Filled.CheckCircle), toast)
    }

    @Test
    fun errorsKeepAnErrorIcon() {
        val toast = nextToast { messages.showError(message = "Could not play station.") }

        assertEquals(Messages.Toast("Error", "Could not play station.", Icons.Default.WarningAmber), toast)
    }

    @Test
    fun staysUpForTwoSeconds() {
        assertEquals(2.seconds, Messages.duration)
    }
}
