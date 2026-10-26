package phanan.koel.app

import androidx.core.content.pm.PackageInfoCompat
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AppVersionTest {
    @Test
    fun theVersionCodeIsAboveTheLastFlutterRelease() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)

        assertTrue(PackageInfoCompat.getLongVersionCode(packageInfo) > LAST_FLUTTER_VERSION_CODE)
    }

    private companion object {
        const val LAST_FLUTTER_VERSION_CODE = 500L
    }
}
