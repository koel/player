import CarPlay
@preconcurrency import Shared

/// The CarPlay screens: tabs for recently played songs, playlists, the library and radio,
/// with the system Now Playing screen on top.
final class CarPlayLibrary: NSObject, CPInterfaceControllerDelegate {
    enum Root: Equatable {
        case message(String)
        case library
        case downloads
    }

    private let app: AppModel
    private let interfaceController: CPInterfaceController
    private var tasks: [Task<Void, Never>] = []
    private var shownRoot: Root?

    init(app: AppModel, interfaceController: CPInterfaceController) {
        self.app = app
        self.interfaceController = interfaceController
        super.init()
        interfaceController.delegate = self
        show(Self.root(for: app.phase, replacing: nil))

        tasks.append(Task { [app] in await app.launchWithoutScreen() })
        tasks.append(Task { [weak self, app] in
            for await phase in Observations({ app.phase }) {
                self?.show(Self.root(for: phase, replacing: self?.shownRoot))
            }
        })
    }

    isolated deinit {
        tasks.forEach { $0.cancel() }
    }

    /// Downloads stay on screen while a reconnect is tried, so a network blip doesn't take the driver back to the root.
    static func root(for phase: AppModel.Phase, replacing shown: Root?) -> Root {
        switch phase {
        case .launching, .loading: shown == .downloads ? .downloads : .message("Loading…")
        case .login: .message("Log in on your iPhone to start listening.")
        case .main: .library
        case .noConnection, .offline: .downloads
        }
    }

    private func show(_ root: Root) {
        guard root != shownRoot else { return }
        shownRoot = root

        let template: CPTemplate = switch root {
        case .message(let text):
            messageTemplate(text)
        case .library:
            CPTabBarTemplate(templates: [recentlyPlayedTab(), playlistsTab(), libraryTab(), radioTab()])
        case .downloads:
            CPTabBarTemplate(templates: [downloadedTab()])
        }
        interfaceController.setRootTemplate(template, animated: false, completion: nil)
    }

    private func messageTemplate(_ text: String) -> CPListTemplate {
        let template = CPListTemplate(title: "Koel", sections: [])
        template.emptyViewTitleVariants = [text]
        return template
    }

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        let shown = (aTemplate as? CPTabBarTemplate)?.selectedTemplate ?? aTemplate
        (shown.userInfo as? Reload)?.run()
        if shownRoot == .downloads {
            tasks.append(Task { [app] in await app.reconnectIfStranded() })
        }
    }

    // MARK: Tabs

    private func recentlyPlayedTab() -> CPListTemplate {
        let template = playablesTemplate(title: "Recently Played") { [app] in
            try await app.core.recentlyPlayed.fetch()
        }
        template.tabImage = UIImage(systemName: "clock")
        return template
    }

    private func playlistsTab() -> CPListTemplate {
        let template = CPListTemplate(title: "Playlists", sections: [])
        template.tabImage = UIImage(systemName: "music.note.list")
        fill(template) { [weak self, app] in
            try await app.core.playlists.fetchAll()
            return app.core.playlists.playlists.value.map { playlist in
                self?.item(text: playlist.name, detail: playlist.isSmart ? Playlist.smartKindLabel : nil, artworkUrl: playlist.cover, fallbackSymbol: "music.note.list") {
                    self?.showPlayables(title: playlist.name) { try await app.core.playables.fetchForPlaylist(playlistId: playlist.id, forceRefresh: false) }
                }
            }
            .compactMap { $0 }
        }
        return template
    }

    private func libraryTab() -> CPListTemplate {
        let rows: [CPListItem] = [
            navigationItem("Favorites", symbol: "heart") { [weak self, app] in
                self?.showPlayables(title: "Favorites") { try await app.core.favorites.fetch() }
            },
            navigationItem("Albums", symbol: "square.stack") { [weak self] in self?.showAlbums() },
            navigationItem("Artists", symbol: "music.microphone") { [weak self] in self?.showArtists() },
            navigationItem("Podcasts", symbol: "mic") { [weak self] in self?.showPodcasts() },
            navigationItem("Downloaded", symbol: "arrow.down.circle") { [weak self, app] in
                self?.showPlayables(title: "Downloaded") { app.core.downloads.playables.value }
            },
        ]
        let template = CPListTemplate(title: "Library", sections: [CPListSection(items: rows)])
        template.tabImage = UIImage(systemName: "square.stack")
        return template
    }

    private func radioTab() -> CPListTemplate {
        let template = CPListTemplate(title: "Radio", sections: [])
        template.tabImage = UIImage(systemName: "dot.radiowaves.left.and.right")
        fill(template, emptyTitle: "No radio stations") { [weak self, app] in
            try await app.core.radioStations.fetchAll()
            return app.core.radioStations.stations.value.compactMap { station in
                self?.item(text: station.name, detail: station.description_, artworkUrl: station.logo, fallbackSymbol: "dot.radiowaves.left.and.right") {
                    self?.playRadio(station)
                }
            }
        }
        return template
    }

    private func downloadedTab() -> CPListTemplate {
        let template = playablesTemplate(title: "Downloaded") { [app] in app.core.downloads.playables.value }
        template.tabImage = UIImage(systemName: "arrow.down.circle")
        return template
    }

    // MARK: Library screens

    private func showAlbums() {
        let template = CPListTemplate(title: "Albums", sections: [])
        fill(template) { [weak self, app] in
            if app.core.albums.items.value.isEmpty { try await app.core.albums.loadMore() }
            return app.core.albums.items.value.compactMap { album in
                self?.item(text: album.name, detail: album.artistName, artworkUrl: album.cover, fallbackSymbol: "square.stack") {
                    self?.showPlayables(title: album.name) { try await app.core.playables.fetchForAlbum(albumId: album.id, forceRefresh: false) }
                }
            }
        }
        interfaceController.pushTemplate(template, animated: true, completion: nil)
    }

    private func showArtists() {
        let template = CPListTemplate(title: "Artists", sections: [])
        fill(template) { [weak self, app] in
            if app.core.artists.items.value.isEmpty { try await app.core.artists.loadMore() }
            return app.core.artists.items.value.compactMap { artist in
                self?.item(text: artist.name, detail: nil, artworkUrl: artist.imageUrl, fallbackSymbol: "music.microphone") {
                    self?.showPlayables(title: artist.name) { try await app.core.playables.fetchForArtist(artistId: artist.id, forceRefresh: false) }
                }
            }
        }
        interfaceController.pushTemplate(template, animated: true, completion: nil)
    }

    private func showPodcasts() {
        let template = CPListTemplate(title: "Podcasts", sections: [])
        fill(template, emptyTitle: "No podcasts") { [weak self, app] in
            try await app.core.podcasts.fetchAll()
            return app.core.podcasts.podcasts.value.compactMap { podcast in
                self?.item(text: podcast.title, detail: podcast.author, artworkUrl: podcast.imageUrl, fallbackSymbol: "mic") {
                    self?.showPlayables(title: podcast.title) {
                        try await app.core.playables.fetchForPodcast(podcastId: podcast.id, forceRefresh: false, checkForNewEpisodes: false)
                    }
                }
            }
        }
        interfaceController.pushTemplate(template, animated: true, completion: nil)
    }

    private func showPlayables(title: String, load: @escaping () async throws -> [any Playable]) {
        interfaceController.pushTemplate(playablesTemplate(title: title, load: load), animated: true, completion: nil)
    }

    // MARK: Building blocks

    /// Songs or episodes; picking one plays the whole list from there.
    private func playablesTemplate(title: String, load: @escaping () async throws -> [any Playable]) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        fill(template) { [weak self] in
            let playables = try await load()
            return playables.compactMap { playable in
                self?.item(text: playable.title, detail: playable.subtitle, artworkUrl: playable.artworkUrl, fallbackSymbol: "music.note") {
                    self?.play(playable, in: playables)
                }
            }
        }
        return template
    }

    /// Loads the list now, and again each time it comes back on screen.
    private func fill(_ template: CPListTemplate, emptyTitle: String = "Nothing here yet", items: @escaping () async throws -> [CPListItem]) {
        template.emptyViewTitleVariants = ["Loading…"]
        let reload = Reload { [weak self, weak template] in
            self?.tasks.append(Task {
                do {
                    let loaded = try await items()
                    template?.emptyViewTitleVariants = [emptyTitle]
                    template?.updateSections([CPListSection(items: Array(loaded.prefix(CPListTemplate.maximumItemCount)))])
                } catch {
                    template?.emptyViewTitleVariants = [LoadFailure.title]
                }
            })
        }
        template.userInfo = reload
        reload.run()
    }

    private func item(text: String, detail: String?, artworkUrl: String?, fallbackSymbol: String, select: @escaping () -> Void) -> CPListItem {
        let item = CPListItem(text: text, detailText: detail, image: UIImage(systemName: fallbackSymbol))
        item.handler = { _, completion in
            select()
            completion()
        }
        if let remote = artworkUrl.flatMap(URL.init(string:)) {
            tasks.append(Task {
                if let image = await ImagePipeline.shared.image(for: remote, pointSize: CPListItem.maximumImageSize.width) {
                    item.setImage(image)
                }
            })
        }
        return item
    }

    private func navigationItem(_ title: String, symbol: String, select: @escaping () -> Void) -> CPListItem {
        let item = CPListItem(text: title, detailText: nil, image: UIImage(systemName: symbol))
        item.accessoryType = .disclosureIndicator
        item.handler = { _, completion in
            select()
            completion()
        }
        return item
    }

    // MARK: Playback

    private func play(_ playable: any Playable, in playables: [any Playable]) {
        app.player.controller.replaceQueue(playables: playables, shuffle: false, autoPlay: false)
        app.player.play(playable)
        showNowPlaying()
    }

    private func playRadio(_ station: RadioStation) {
        Task {
            try? await app.player.controller.playRadio(station: station)
        }
        showNowPlaying()
    }

    private func showNowPlaying() {
        let nowPlaying = CPNowPlayingTemplate.shared
        guard interfaceController.topTemplate !== nowPlaying else { return }
        interfaceController.pushTemplate(nowPlaying, animated: true, completion: nil)
    }
}

private struct Reload {
    let run: () -> Void
}
