package phanan.koel.app.ui.library

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import kotlinx.coroutines.launch
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.ArtworkCard
import phanan.koel.app.ui.main.Route
import phanan.koel.shared.models.Podcast
import phanan.koel.shared.models.RadioStation

/** A podcast in a shelf: tap opens it, long-press shows its menu. */
@Composable
fun PodcastCard(podcast: Podcast) {
    val app = LocalAppModel.current
    var isShowingMenu by remember { mutableStateOf(false) }

    if (isShowingMenu) PodcastMenuSheet(podcast) { isShowingMenu = false }

    ArtworkCard(podcast.imageUrl, podcast.title, subtitle = podcast.author, onLongClick = { isShowingMenu = true }) {
        app.navigator.push(Route.Podcast(podcast.id))
    }
}

/** A radio station in a shelf: tap plays it, long-press shows its menu. */
@Composable
fun RadioStationCard(station: RadioStation) {
    val app = LocalAppModel.current
    val scope = rememberCoroutineScope()
    var isShowingMenu by remember { mutableStateOf(false) }

    if (isShowingMenu) RadioStationMenuSheet(station) { isShowingMenu = false }

    ArtworkCard(station.logo, station.name, subtitle = station.description, onLongClick = { isShowingMenu = true }) {
        scope.launch {
            runCatching { app.core.player.playRadio(station) }.onFailure { app.messages.showError(message = "Could not play station.") }
        }
    }
}
