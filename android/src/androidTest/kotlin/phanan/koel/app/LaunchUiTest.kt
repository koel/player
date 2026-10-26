package phanan.koel.app

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import phanan.koel.app.ui.components.LoadFailure
import phanan.koel.app.ui.main.AppTab
import phanan.koel.app.ui.main.Route

@OptIn(ExperimentalTestApi::class)
@RunWith(AndroidJUnit4::class)
class LaunchUiTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var server: MockKoelServer
    private lateinit var scenario: ActivityScenario<MainActivity>

    private val app get() = (InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as KoelApplication).app

    @Before
    fun setUp() {
        val audio = InstrumentationRegistry.getInstrumentation().context.assets.open("tone.mp3").use { it.readBytes() }
        server = MockKoelServer(audio).apply {
            checksLoginSlowly = true
            start()
        }
    }

    @After
    fun tearDown() {
        runBlocking(Dispatchers.Main) { app.logOut().join() }
        scenario.close()
        server.stop()
    }

    @Test
    fun theLogoShowsWhileTheLoginIsChecked() {
        launchLoggedIn()

        compose.waitUntilAtLeastOneExists(hasContentDescription("Koel"), 5_000)
        compose.waitUntilDoesNotExist(hasText("Log In"), 1_000)
        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), 30_000)
    }

    @Test
    fun recreatingTheActivityWhileTheLoginIsCheckedCarriesOn() {
        launchLoggedIn()
        compose.waitUntilAtLeastOneExists(hasContentDescription("Koel"), 5_000)

        scenario.recreate()

        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), 30_000)
        compose.onNodeWithText("You are offline.").assertDoesNotExist()
    }

    @Test
    fun aFailingServerOffersRetryAndRecoversOnceItIsBack() {
        server.failsRequests = true
        launchLoggedIn()

        compose.waitUntilAtLeastOneExists(hasText(LoadFailure.RETRY), 30_000)
        compose.onNodeWithText("Log Out").assertExists()
        compose.onNodeWithText("You are offline.").assertDoesNotExist()

        server.failsRequests = false
        compose.onNodeWithText(LoadFailure.RETRY).performClick()

        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), 30_000)
        assertEquals(MockKoelServer.EMAIL, app.core.auth.currentUser.value?.email)
    }

    @Test
    fun aTokenRejectedAtLaunchLogsOutAsFullyAsLoggingOut() {
        server.rejectsToken = true
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        runBlocking(Dispatchers.Main) {
            app.logOut().join()
            app.core.auth.startSession(server.host, MockKoelServer.TOKEN, MockKoelServer.TOKEN)
            app.navigator.select(AppTab.Library)
            app.navigator.push(Route.Albums)
            app.reconnect()
        }

        scenario = ActivityScenario.launch(LaunchAction.PlayFavorites.intent(context))

        compose.waitUntilAtLeastOneExists(hasText("Log In"), 30_000)
        assertEquals(AppTab.Home, app.navigator.selectedTab)
        assertEquals(listOf(Route.Library), app.navigator.stack(AppTab.Library).toList())
        assertNull(app.pendingLaunch)
    }

    private fun launchLoggedIn() {
        runBlocking(Dispatchers.Main) {
            app.logOut().join()
            app.core.auth.startSession(server.host, MockKoelServer.TOKEN, MockKoelServer.TOKEN)
            app.reconnect()
        }
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }
}
