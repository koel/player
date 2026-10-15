package phanan.koel.shared.storage

import kotlinx.io.files.Path
import phanan.koel.shared.player.RepeatMode
import phanan.koel.shared.support.temporaryDirectory
import phanan.koel.shared.support.writeText
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class FlutterDataMigrationTest {
    private val documents = temporaryDirectory()
    private val preferences = Preferences(InMemoryKeyValueStore())

    private fun migrate() = FlutterDataMigration(preferences, documents.toString()).run()

    private fun writeFlutterPreferences(json: String) = Path(documents, "Preferences.gs").writeText(json)

    @Test
    fun copiesTheFlutterPreferences() {
        writeFlutterPreferences(
            """{"hostUrl":"https://koel.test","apiToken":"api","audioToken":"audio","email":"me@koel.test",""" +
                """"repeatMode":"one","volume":0.4,"transcoding":false}""",
        )

        migrate()

        assertEquals("https://koel.test", preferences.host)
        assertEquals("api", preferences.apiToken)
        assertEquals("audio", preferences.audioToken)
        assertEquals("me@koel.test", preferences.userEmail)
        assertEquals(RepeatMode.ONE, preferences.repeatMode)
        assertEquals(0.4, preferences.volume)
    }

    @Test
    fun fallsBackToTheBackupWhenTheMainFileIsCorrupt() {
        writeFlutterPreferences("{\"hostUrl\":")
        Path(documents, "Preferences.bak").writeText("""{"hostUrl":"https://koel.test","apiToken":"api"}""")

        migrate()

        assertEquals("https://koel.test", preferences.host)
        assertEquals("api", preferences.apiToken)
    }

    @Test
    fun leavesNativePreferencesAlone() {
        writeFlutterPreferences("""{"hostUrl":"https://flutter.test","apiToken":"flutter-token"}""")
        preferences.host = "https://koel.test"
        preferences.apiToken = null

        migrate()
        migrate()

        assertEquals("https://koel.test", preferences.host)
        assertNull(preferences.apiToken)
    }

    @Test
    fun doesNothingWithoutFlutterData() {
        migrate()

        assertNull(preferences.host)
        assertNull(preferences.apiToken)
        assertEquals(RepeatMode.NONE, preferences.repeatMode)
    }
}
