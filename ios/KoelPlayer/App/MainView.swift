@preconcurrency import Shared
import SwiftUI

struct MainView: View {
    @Environment(AppModel.self) private var app
    @Namespace private var nowPlayingTransition

    var body: some View {
        @Bindable var app = app
        @Bindable var navigator = app.navigator

        TabView(selection: Binding(get: { navigator.selectedTab }, set: { navigator.select($0) })) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                stack(for: .home) { HomeView() }
            }
            Tab("Library", systemImage: "square.stack.fill", value: AppTab.library) {
                stack(for: .library) { LibraryView() }
            }
            Tab(value: AppTab.search, role: .search) {
                stack(for: .search) { SearchView() }
            }
        }
        .tint(.highlight)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: app.player.hasSomethingToShow) {
            MiniPlayer()
                .tint(.primary)
                .matchedTransitionSource(id: "now-playing", in: nowPlayingTransition)
        }
        .fullScreenCover(isPresented: $app.isNowPlayingPresented) {
            NowPlayingView()
                .navigationTransition(.zoom(sourceID: "now-playing", in: nowPlayingTransition))
        }
        .sheet(item: $app.sheet) { sheet in
            switch sheet {
            case .addToPlaylist(let playables):
                AddToPlaylistView(playables: playables)
            case .details(let playable):
                PlayableDetailsView(playable: playable)
            }
        }
        .modifier(ToastOverlay(toasts: app.toasts))
        .task { await QuickActions.handle(app: app) }
    }

    private func stack(for tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: app.navigator.path(for: tab)) {
            root().routeDestinations()
        }
        .tint(.primary)
    }
}

extension View {
    func routeDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .songs: SongsView()
            case .albums: AlbumsView()
            case .artists: ArtistsView()
            case .genres: GenresView()
            case .playlists: PlaylistsView()
            case .favorites: FavoritesView()
            case .downloads: DownloadsView()
            case .recentlyPlayed: RecentlyPlayedView()
            case .podcasts: PodcastsView()
            case .radioStations: RadioStationsView()
            case .album(let id): AlbumDetailView(albumId: id)
            case .artist(let id): ArtistDetailView(artistId: id)
            case .playlist(let id): PlaylistDetailView(playlistId: id)
            case .podcast(let id): PodcastDetailView(podcastId: id)
            case .genre(let id, let name): GenreDetailView(genreId: id, name: name)
            case .searchSongs(let keywords): SearchSongsView(keywords: keywords)
            }
        }
    }
}
