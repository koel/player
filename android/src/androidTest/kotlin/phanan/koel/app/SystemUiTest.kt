package phanan.koel.app

import android.content.ComponentName
import android.content.pm.ActivityInfo
import android.os.ParcelFileDescriptor
import androidx.core.view.WindowCompat
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SystemUiTest {
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()

    @Test
    fun theAppStaysInPortrait() {
        val context = instrumentation.targetContext
        val activity = context.packageManager.getActivityInfo(ComponentName(context, MainActivity::class.java), 0)

        assertEquals(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT, activity.screenOrientation)
    }

    @Test
    fun theStatusBarIconsStayLightInTheSystemLightMode() {
        val nightModeBefore = shell("cmd uimode night").substringAfter(": ").trim()
        shell("cmd uimode night no")
        try {
            ActivityScenario.launch(MainActivity::class.java).use { scenario ->
                scenario.onActivity { activity ->
                    val bars = WindowCompat.getInsetsController(activity.window, activity.window.decorView)
                    assertFalse(bars.isAppearanceLightStatusBars)
                    assertFalse(bars.isAppearanceLightNavigationBars)
                }
            }
        } finally {
            shell("cmd uimode night $nightModeBefore")
        }
    }

    private fun shell(command: String): String =
        instrumentation.uiAutomation.executeShellCommand(command).let { descriptor ->
            ParcelFileDescriptor.AutoCloseInputStream(descriptor).bufferedReader().use { it.readText() }
        }
}
