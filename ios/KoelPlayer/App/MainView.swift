@preconcurrency import Shared
import SwiftUI

struct MainView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.brandColor) private var brandColor
    @Namespace private var nowPlayingTransition

    var body: some View {
        @Bindable var app = app
        @Bindable var navigator = app.navigator

        TabView(selection: Binding(get: { navigator.selectedTab }, set: { navigator.select($0) })) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                stack(for: .home) { HomeView() }
            }
            Tab("Library", systemImage: "music.note.square.stack.fill", value: AppTab.library) {
                stack(for: .library) { LibraryView() }
            }
            Tab(value: AppTab.search, role: .search) {
                stack(for: .search) { SearchView() }
            }
        }
        .tint(brandColor)
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
        .appSheets(isFrontmost: !app.isNowPlayingPresented)
    }

    private func stack(for tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: app.navigator.path(for: tab)) {
            root().clearOfTabBar().routeDestinations()
        }
        .tint(.primary)
        .modifier(ToastOverlay(
            toasts: app.toasts,
            isShown: !app.isNowPlayingPresented && app.navigator.selectedTab == tab,
            bottomPadding: Toasts.bottomPaddingAboveBars
        ))
    }
}

extension View {
    func routeDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            routeDestination(route).clearOfTabBar()
        }
    }

    /// Extra room at the end of every scrolled screen, so the last item doesn't sit against the tab bar or the mini player.
    func clearOfTabBar() -> some View {
        safeAreaPadding(.bottom, 16)
    }

    @ViewBuilder
    private func routeDestination(_ route: Route) -> some View {
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
        case .artistSongs(let id): ArtistSongsView(artistId: id)
        case .playlist(let id): PlaylistDetailView(playlistId: id)
        case .podcast(let id): PodcastDetailView(podcastId: id)
        case .genre(let id, let name): GenreDetailView(genreId: id, name: name)
        case .searchSongs(let keywords): SearchSongsView(keywords: keywords)
        }
    }
}
