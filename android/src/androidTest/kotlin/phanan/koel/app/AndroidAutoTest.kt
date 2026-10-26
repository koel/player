package phanan.koel.app

import android.content.ComponentName
import androidx.media3.common.MediaItem
import androidx.media3.session.MediaBrowser
import androidx.media3.session.SessionToken
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import phanan.koel.app.audio.PlaybackService

/** Browses the library the way Android Auto does, with no phone screen open. */
@RunWith(AndroidJUnit4::class)
class AndroidAutoTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val app get() = (context.applicationContext as KoelApplication).app

    @After
    fun tearDown() {
        runBlocking(Dispatchers.Main) { app.logOut().join() }
    }

    @Test
    fun anUnreachableServerOffersTheDownloadsInsteadOfAskingToLogIn() {
        val server = MockKoelServer(ByteArray(0)).apply { start() }
        val unreachableHost = server.host
        server.stop()
        startSession(unreachableHost)

        assertEquals(listOf("Downloaded"), browseRoot())
        assertEquals(AppModel.Phase.Offline, app.phase.value)
    }

    @Test
    fun aFailingServerOffersTheDownloadsAndIsTriedAgainOnTheNextBrowse() {
        val server = MockKoelServer(ByteArray(0)).apply {
            failsRequests = true
            start()
        }
        try {
            startSession(server.host)
            assertEquals(listOf("Downloaded"), browseRoot())

            server.failsRequests = false

            assertEquals(LIBRARY_TABS, browseRoot())
            assertEquals(AppModel.Phase.Main, app.phase.value)
        } finally {
            server.stop()
        }
    }

    @Test
    fun browsingSeveralFoldersAtOnceOnAColdStartLaunchesOnce() {
        val server = MockKoelServer(ByteArray(0)).apply {
            checksLoginSlowly = true
            start()
        }
        try {
            startSession(server.host)

            val roots = runBlocking(Dispatchers.Main) {
                withBrowser { browser, rootId ->
                    List(3) { async { browser.getChildren(rootId, 0, Int.MAX_VALUE, null).await().value?.titles() } }.awaitAll()
                }
            }

            assertEquals(List(3) { LIBRARY_TABS }, roots)
            assertEquals(1, server.requestCount("/api/data"))
        } finally {
            server.stop()
        }
    }

    @Test
    fun aRejectedLoginAsksToLogInOnThePhone() {
        val server = MockKoelServer(ByteArray(0)).apply {
            rejectsToken = true
            start()
        }
        try {
            startSession(server.host)

            assertNull(browseRoot())
            assertEquals(AppModel.Phase.Login, app.phase.value)
        } finally {
            server.stop()
        }
    }

    private fun startSession(host: String) = runBlocking(Dispatchers.Main) {
        app.logOut().join()
        app.core.auth.startSession(host, MockKoelServer.TOKEN, MockKoelServer.TOKEN)
        app.reconnect()
    }

    /** The root folder's titles, or null when Android Auto is told to log in on the phone. */
    private fun browseRoot(): List<String>? = runBlocking(Dispatchers.Main) {
        withBrowser { browser, rootId -> browser.getChildren(rootId, 0, Int.MAX_VALUE, null).await().value?.titles() }
    }

    private suspend fun <T> withBrowser(browse: suspend (MediaBrowser, String) -> T): T {
        val browser = MediaBrowser.Builder(context, SessionToken(context, ComponentName(context, PlaybackService::class.java)))
            .buildAsync()
            .await()
        try {
            return browse(browser, browser.getLibraryRoot(null).await().value!!.mediaId)
        } finally {
            browser.release()
        }
    }

    private fun List<MediaItem>.titles() = map { it.mediaMetadata.title.toString() }

    private companion object {
        val LIBRARY_TABS = listOf("Recently Played", "Playlists", "Library", "Radio")
    }
}
