import Observation
@preconcurrency import Shared

/// The overview sections Home shows, mirrored from the shared `OverviewStore`.
@Observable
final class HomeFeed {
    enum Items {
        case songs([any Playable])
        case albums([Album])
        case artists([Artist])

        var isEmpty: Bool {
            switch self {
            case .songs(let songs): songs.isEmpty
            case .albums(let albums): albums.isEmpty
            case .artists(let artists): artists.isEmpty
            }
        }
    }

    static let recentlyPlayedLimit = 4

    private let store: OverviewStore
    private let mostPlayedSongs: Live<[any Playable]>
    private let recentlyAddedSongs: Live<[any Playable]>
    private let leastPlayedSongs: Live<[any Playable]>
    private let randomSongs: Live<[any Playable]>
    private let similarSongs: Live<[any Playable]>
    private let mostPlayedAlbums: Live<[Album]>
    private let recentlyAddedAlbums: Live<[Album]>
    private let randomAlbums: Live<[Album]>
    private let mostPlayedArtists: Live<[Artist]>
    private let recentlyAddedArtists: Live<[Artist]>
    private let randomArtists: Live<[Artist]>
    private let recentlyPlayedItems: Live<[any Playable]>
    private let currentUser: Live<User?>

    init(core: KoelCore) {
        let overview = core.overview
        store = overview
        mostPlayedSongs = Live(overview.mostPlayedSongs)
        recentlyAddedSongs = Live(overview.recentlyAddedSongs)
        leastPlayedSongs = Live(overview.leastPlayedSongs)
        randomSongs = Live(overview.randomSongs)
        similarSongs = Live(overview.similarSongs)
        mostPlayedAlbums = Live(overview.mostPlayedAlbums)
        recentlyAddedAlbums = Live(overview.recentlyAddedAlbums)
        randomAlbums = Live(overview.randomAlbums)
        mostPlayedArtists = Live(overview.mostPlayedArtists)
        recentlyAddedArtists = Live(overview.recentlyAddedArtists)
        randomArtists = Live(overview.randomArtists)
        recentlyPlayedItems = Live(core.recentlyPlayed.items)
        currentUser = Live(core.auth.currentUser)
    }

    var user: User? { currentUser.value }

    var recentlyPlayed: [any Playable] {
        Array(recentlyPlayedItems.value.prefix(Self.recentlyPlayedLimit))
    }

    /// The user's saved order, without the blocks that have nothing to show.
    var blocks: [HomeBlock] {
        HomeBlock.ordered(by: user?.preferences.homeBlocksOrder ?? [])
            .filter { !items(for: $0).isEmpty }
    }

    var isEmpty: Bool {
        recentlyPlayed.isEmpty && blocks.isEmpty
    }

    func refresh() async throws {
        try await store.refresh()
    }

    func items(for block: HomeBlock) -> Items {
        switch block {
        case .recentlyAddedAlbums: .albums(recentlyAddedAlbums.value)
        case .similarSongs: .songs(similarSongs.value)
        case .mostPlayedAlbums: .albums(mostPlayedAlbums.value)
        case .mostPlayedSongs: .songs(mostPlayedSongs.value)
        case .mostPlayedArtists: .artists(mostPlayedArtists.value)
        case .recentlyAddedSongs: .songs(recentlyAddedSongs.value)
        case .recentlyAddedArtists: .artists(recentlyAddedArtists.value)
        case .leastPlayedSongs: .songs(leastPlayedSongs.value)
        case .randomSongs: .songs(randomSongs.value)
        case .randomAlbums: .albums(randomAlbums.value)
        case .randomArtists: .artists(randomArtists.value)
        }
    }
}
