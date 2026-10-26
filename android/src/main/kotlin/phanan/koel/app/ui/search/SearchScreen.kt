package phanan.koel.app.ui.search

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import phanan.koel.app.AppSheet
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.PlayableSection
import phanan.koel.app.ui.components.ArtworkCard
import phanan.koel.app.ui.components.BrandMeshHeaderBackground
import phanan.koel.app.ui.components.LoadingRows
import phanan.koel.app.ui.components.NoResults
import phanan.koel.app.ui.components.SectionSpacing
import phanan.koel.app.ui.components.Shelf
import phanan.koel.app.ui.components.ScreenBottomPadding
import phanan.koel.app.ui.library.AlbumMenuSheet
import phanan.koel.app.ui.library.ArtistMenuSheet
import phanan.koel.app.ui.library.PodcastCard
import phanan.koel.app.ui.library.RadioStationCard
import phanan.koel.app.ui.main.Route
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelInputs
import phanan.koel.app.ui.theme.LocalBrandColor
import phanan.koel.shared.models.Album
import phanan.koel.shared.models.Artist
import phanan.koel.shared.session.Feature
import phanan.koel.shared.stores.SearchResult

/** The groups a search result is shown in, in Flutter's order. */
enum class SearchSection(val title: String) {
    Songs("Songs"),
    Albums("Albums"),
    Artists("Artists"),
    Podcasts("Podcasts"),
    RadioStations("Radio Stations");

    companion object {
        /** The sections with results, leaving out features the server doesn't support. */
        fun visible(result: SearchResult, supports: (Feature) -> Boolean): List<SearchSection> = entries.filter {
            when (it) {
                Songs -> result.playables.isNotEmpty()
                Albums -> result.albums.isNotEmpty()
                Artists -> result.artists.isNotEmpty()
                Podcasts -> supports(Feature.PODCASTS) && result.podcasts.isNotEmpty()
                RadioStations -> supports(Feature.RADIO_STATIONS) && result.radioStations.isNotEmpty()
            }
        }
    }
}

const val SEARCH_SKELETON_TAG = "search-skeleton"

@Composable
fun SearchScreen() {
    val app = LocalAppModel.current
    var query by rememberSaveable { mutableStateOf("") }
    var result by remember { mutableStateOf<SearchResult?>(null) }
    var searchedKeywords by remember { mutableStateOf("") }
    var isSearching by remember { mutableStateOf(false) }
    var albumMenu by remember { mutableStateOf<Album?>(null) }
    var artistMenu by remember { mutableStateOf<Artist?>(null) }
    val keywords = query.trim()
    val listState = rememberLazyListState()

    LaunchedEffect(keywords) {
        if (keywords.length < 2) {
            if (keywords.isEmpty()) result = null
            isSearching = false
            return@LaunchedEffect
        }
        result = null
        isSearching = true
        delay(300)
        try {
            result = app.core.search.searchExcerpts(keywords)
            searchedKeywords = keywords
            isSearching = false
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            app.messages.showError()
            isSearching = false
        }
    }

    albumMenu?.let { AlbumMenuSheet(it) { albumMenu = null } }
    artistMenu?.let { ArtistMenuSheet(it) { artistMenu = null } }

    val found = result
    val sections = found?.let { SearchSection.visible(it, app.core.session::supports) }.orEmpty()

    Box(Modifier.fillMaxSize()) {
        BrandMeshHeaderBackground(scrolledDistance = {
            if (listState.firstVisibleItemIndex == 0) listState.firstVisibleItemScrollOffset.toFloat() else Float.MAX_VALUE
        })
        LazyColumn(
            state = listState,
            contentPadding = PaddingValues(bottom = ScreenBottomPadding),
            modifier = Modifier.statusBarsPadding(),
        ) {
            item(key = "title") {
                Text(
                    "Search",
                    style = MaterialTheme.typography.headlineLarge.copy(fontSize = 34.sp, fontWeight = FontWeight.Bold),
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 56.dp),
                )
            }
            item(key = "field") {
                SearchField(query) { query = it }
            }
            if (isSearching) {
                item(key = "skeleton") {
                    Box(Modifier.padding(top = 8.dp).testTag(SEARCH_SKELETON_TAG)) { LoadingRows(count = 5) }
                }
            }
            if (found != null && sections.isEmpty() && !isSearching) {
                item(key = "no-results") { NoResults(searchedKeywords) }
            }
            sections.forEach { section ->
                item(key = section.name) {
                    Box(Modifier.padding(top = if (section == sections.first()) 8.dp else SectionSpacing)) {
                        when (section) {
                            SearchSection.Songs -> SongResults(found!!, searchedKeywords)
                            SearchSection.Albums -> Shelf(section.title, found!!.albums, key = { it.id }) { album ->
                                ArtworkCard(album.cover, album.name, subtitle = album.artistName, onLongClick = { albumMenu = album }) {
                                    app.navigator.push(Route.Album(album.id))
                                }
                            }
                            SearchSection.Artists -> Shelf(section.title, found!!.artists, key = { it.id }) { artist ->
                                ArtworkCard(artist.imageUrl, artist.name, isCircular = true, onLongClick = { artistMenu = artist }) {
                                    app.navigator.push(Route.Artist(artist.id))
                                }
                            }
                            SearchSection.Podcasts -> Shelf(section.title, found!!.podcasts, key = { it.id }) { PodcastCard(it) }
                            SearchSection.RadioStations -> Shelf(section.title, found!!.radioStations, key = { it.id }) { RadioStationCard(it) }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchField(query: String, onChange: (String) -> Unit) {
    val navigator = LocalAppModel.current.navigator
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(navigator.wantsSearchFocus) {
        if (!navigator.wantsSearchFocus) return@LaunchedEffect
        focusRequester.requestFocus()
        navigator.wantsSearchFocus = false
    }

    TextField(
        value = query,
        onValueChange = onChange,
        placeholder = { Text("Search your library") },
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onChange("") }) { Icon(Icons.Default.Cancel, contentDescription = "Clear") }
            }
        },
        singleLine = true,
        shape = KoelInputs.shape,
        colors = KoelInputs.colors().copy(
            focusedContainerColor = KoelColors.hairline,
            unfocusedContainerColor = KoelColors.hairline,
            focusedLeadingIconColor = KoelColors.secondaryText,
            unfocusedLeadingIconColor = KoelColors.faintText,
            focusedTrailingIconColor = KoelColors.faintText,
            unfocusedTrailingIconColor = KoelColors.faintText,
        ),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).focusRequester(focusRequester),
    )
}

@Composable
private fun SongResults(result: SearchResult, keywords: String) {
    val app = LocalAppModel.current
    PlayableSection(SearchSection.Songs.title, result.playables) { app.navigator.push(Route.SearchSongs(keywords)) }
}
