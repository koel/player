package phanan.koel.app

import android.content.Context
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Logs in to a [MockKoelServer] that asks for a two-factor code. */
@OptIn(ExperimentalTestApi::class)
@RunWith(AndroidJUnit4::class)
class TwoFactorUiTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var server: MockKoelServer
    private lateinit var scenario: ActivityScenario<MainActivity>

    private val app get() = (InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as KoelApplication).app

    @Before
    fun setUp() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val audio = instrumentation.context.assets.open("tone.mp3").use { it.readBytes() }
        server = MockKoelServer(audio).apply {
            requiresTwoFactor = true
            start()
        }

        runBlocking(Dispatchers.Main) { app.logOut().join() }
        instrumentation.targetContext.getSharedPreferences("koel", Context.MODE_PRIVATE).edit().clear().commit()
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun tearDown() {
        runBlocking(Dispatchers.Main) { app.logOut().join() }
        scenario.close()
        server.stop()
    }

    @Test
    fun typingTheSixDigitsSendsTheCode() {
        openTwoFactor()
        compose.onNodeWithContentDescription("Authentication code").performTextInput("123456")

        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), 30_000)
        assertEquals("123456", server.twoFactorCode)
    }

    @Test
    fun goingBackToLoginSlidesTheTwoFactorPageAway() {
        openTwoFactor()
        compose.mainClock.autoAdvance = false

        compose.onNodeWithText("Back to login").performClick()
        compose.mainClock.advanceTimeBy(100)

        compose.onNodeWithContentDescription("Authentication code").assertExists()
        compose.onNodeWithText("Host").assertExists()

        compose.mainClock.autoAdvance = true
        compose.waitUntilDoesNotExist(hasContentDescription("Authentication code"), 5_000)
    }

    @Test
    fun theTwoFactorPageSurvivesRecreatingTheActivity() {
        openTwoFactor()

        scenario.recreate()

        compose.waitUntilAtLeastOneExists(hasContentDescription("Authentication code"), 5_000)
        compose.onNodeWithContentDescription("Authentication code").performTextInput("123456")
        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), 30_000)
    }

    @Test
    fun recreatingTheActivityMidLoginKeepsTheLoginGoing() {
        server.logsInSlowly = true
        submitLoginForm()

        scenario.recreate()

        compose.waitUntilAtLeastOneExists(hasContentDescription("Authentication code"), MockKoelServer.SLOW_LOGIN_SECONDS * 1_000 + 10_000)
    }

    @Test
    fun recreatingTheActivityMidVerifyKeepsTheVerifyGoing() {
        openTwoFactor()
        server.verifiesTwoFactorSlowly = true
        compose.onNodeWithContentDescription("Authentication code").performTextInput("123456")

        scenario.recreate()

        compose.waitUntilAtLeastOneExists(hasContentDescription("Recently Played"), MockKoelServer.SLOW_LOGIN_SECONDS * 1_000 + 30_000)
        assertEquals("123456", server.twoFactorCode)
    }

    private fun openTwoFactor() {
        submitLoginForm()
        compose.waitUntilAtLeastOneExists(hasContentDescription("Authentication code"), 15_000)
        compose.waitForIdle()
    }

    private fun submitLoginForm() {
        compose.waitUntilAtLeastOneExists(hasText("Host"), 15_000)
        compose.onNodeWithText("Host").performTextInput(server.host)
        compose.onNodeWithText("Email").performTextInput(MockKoelServer.EMAIL)
        compose.onNodeWithText("Password").performTextInput(MockKoelServer.PASSWORD)
        compose.onNodeWithText("Log In").performClick()
    }
}
