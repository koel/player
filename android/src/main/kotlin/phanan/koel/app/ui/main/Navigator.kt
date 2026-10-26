package phanan.koel.app.ui.main

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import org.json.JSONArray
import org.json.JSONObject
import phanan.koel.shared.storage.KeyValueStore

enum class AppTab { Home, Library, Search }

sealed interface Route {
    data object Home : Route
    data object Library : Route
    data object Search : Route
    data object Songs : Route
    data object Albums : Route
    data object Artists : Route
    data object Genres : Route
    data object Playlists : Route
    data object Favorites : Route
    data object Downloads : Route
    data object RecentlyPlayed : Route
    data object Podcasts : Route
    data object RadioStations : Route
    data class Album(val id: String) : Route
    data class Artist(val id: String) : Route
    data class ArtistSongs(val id: String) : Route
    data class Playlist(val id: String) : Route
    data class Podcast(val id: String) : Route
    data class Genre(val id: String, val name: String) : Route
    data class SearchSongs(val keywords: String) : Route
}

/** One back stack per tab, like the iOS app, kept in [store] so the app reopens where it was. */
class Navigator(private val store: KeyValueStore? = null) {
    var selectedTab by mutableStateOf(AppTab.Home)
        private set

    private val stacks: Map<AppTab, SnapshotStateList<Route>> = AppTab.entries.associateWith { tab ->
        mutableStateListOf(root(tab))
    }

    init {
        restore()
    }

    fun stack(tab: AppTab): SnapshotStateList<Route> = stacks.getValue(tab)

    /** Picking the tab that's already showing goes back to its first screen. */
    fun select(tab: AppTab) {
        if (tab == selectedTab) popToRoot(tab) else selectedTab = tab
        if (tab == AppTab.Search) wantsSearchFocus = true
        persist()
    }

    /** Set when something asks for the search field, until the Search screen takes the focus. */
    var wantsSearchFocus by mutableStateOf(false)

    fun focusSearch() {
        selectedTab = AppTab.Search
        wantsSearchFocus = true
        persist()
    }

    fun push(route: Route) {
        stack(selectedTab).add(route)
        persist()
    }

    fun pop(): Boolean {
        val stack = stack(selectedTab)
        if (stack.size <= 1) return false
        stack.removeAt(stack.lastIndex)
        persist()
        return true
    }

    fun reset() {
        AppTab.entries.forEach(::popToRoot)
        selectedTab = AppTab.Home
        persist()
    }

    private fun persist() {
        val state = JSONObject().put("tab", selectedTab.name)
        AppTab.entries.forEach { tab -> state.put(tab.name, JSONArray(stack(tab).drop(1).map(::encode))) }
        store?.set(STORAGE_KEY, state.toString())
    }

    private fun restore() {
        val state = store?.get(STORAGE_KEY)?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return
        AppTab.entries.forEach { tab ->
            val saved = state.optJSONArray(tab.name) ?: return@forEach
            stack(tab).addAll((0 until saved.length()).mapNotNull { index -> saved.optJSONArray(index)?.let(::decode) })
        }
        selectedTab = AppTab.entries.firstOrNull { it.name == state.optString("tab") } ?: AppTab.Home
    }

    private fun popToRoot(tab: AppTab) {
        val stack = stack(tab)
        while (stack.size > 1) stack.removeAt(stack.lastIndex)
    }

    private companion object {
        const val STORAGE_KEY = "navigation"

        fun encode(route: Route): JSONArray = when (route) {
            is Route.Album -> JSONArray(listOf("Album", route.id))
            is Route.Artist -> JSONArray(listOf("Artist", route.id))
            is Route.ArtistSongs -> JSONArray(listOf("ArtistSongs", route.id))
            is Route.Playlist -> JSONArray(listOf("Playlist", route.id))
            is Route.Podcast -> JSONArray(listOf("Podcast", route.id))
            is Route.Genre -> JSONArray(listOf("Genre", route.id, route.name))
            is Route.SearchSongs -> JSONArray(listOf("SearchSongs", route.keywords))
            else -> JSONArray(listOf(route.toString()))
        }

        fun decode(saved: JSONArray): Route? {
            val argument = saved.optString(1)
            return when (saved.optString(0)) {
                "Album" -> Route.Album(argument)
                "Artist" -> Route.Artist(argument)
                "ArtistSongs" -> Route.ArtistSongs(argument)
                "Playlist" -> Route.Playlist(argument)
                "Podcast" -> Route.Podcast(argument)
                "Genre" -> Route.Genre(argument, saved.optString(2))
                "SearchSongs" -> Route.SearchSongs(argument)
                else -> pushableObjects.firstOrNull { it.toString() == saved.optString(0) }
            }
        }

        val pushableObjects = listOf(
            Route.Songs, Route.Albums, Route.Artists, Route.Genres, Route.Playlists, Route.Favorites,
            Route.Downloads, Route.RecentlyPlayed, Route.Podcasts, Route.RadioStations,
        )
    }

    private fun root(tab: AppTab): Route = when (tab) {
        AppTab.Home -> Route.Home
        AppTab.Library -> Route.Library
        AppTab.Search -> Route.Search
    }
}
