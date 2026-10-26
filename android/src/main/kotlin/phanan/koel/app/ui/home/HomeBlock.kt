package phanan.koel.app.ui.home

import kotlinx.coroutines.flow.StateFlow
import phanan.koel.app.ui.main.Route
import phanan.koel.shared.stores.OverviewStore

/**
 * The shelves on Home, in koel web's default order. [id]s are what the server stores in the
 * user's `home_blocks_order` preference.
 */
enum class HomeBlock(val id: String, val title: String) {
    RecentlyAddedAlbums("recently-added-albums", "Latest Albums"),
    SimilarSongs("similar-songs", "You Might Also Like"),
    MostPlayedAlbums("most-played-albums", "Top Albums"),
    MostPlayedSongs("most-played-songs", "Most Played"),
    MostPlayedArtists("most-played-artists", "Top Artists"),
    RecentlyAddedSongs("recently-added-songs", "New Songs"),
    RecentlyAddedArtists("recently-added-artists", "New Artists"),
    LeastPlayedSongs("least-played-songs", "Hidden Gems"),
    RandomSongs("random-songs", "Random Songs"),
    RandomAlbums("random-albums", "Random Albums"),
    RandomArtists("random-artists", "Random Artists");

    /** The full list a shelf's header opens. */
    val seeAll: Route
        get() = when (this) {
            RecentlyAddedAlbums, MostPlayedAlbums, RandomAlbums -> Route.Albums
            MostPlayedArtists, RecentlyAddedArtists, RandomArtists -> Route.Artists
            else -> Route.Songs
        }

    fun items(overview: OverviewStore): StateFlow<List<Any>> = when (this) {
        RecentlyAddedAlbums -> overview.recentlyAddedAlbums
        SimilarSongs -> overview.similarSongs
        MostPlayedAlbums -> overview.mostPlayedAlbums
        MostPlayedSongs -> overview.mostPlayedSongs
        MostPlayedArtists -> overview.mostPlayedArtists
        RecentlyAddedSongs -> overview.recentlyAddedSongs
        RecentlyAddedArtists -> overview.recentlyAddedArtists
        LeastPlayedSongs -> overview.leastPlayedSongs
        RandomSongs -> overview.randomSongs
        RandomAlbums -> overview.randomAlbums
        RandomArtists -> overview.randomArtists
    }

    companion object {
        /** Blocks named in [savedOrder] come first, in that order; the rest keep their default order. */
        fun ordered(savedOrder: List<String>): List<HomeBlock> =
            entries.sortedBy { block -> savedOrder.indexOf(block.id).takeIf { it >= 0 } ?: (savedOrder.size + block.ordinal) }
    }
}
