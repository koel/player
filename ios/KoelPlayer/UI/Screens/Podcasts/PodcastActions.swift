@preconcurrency import Shared
import SwiftUI

/// Podcast actions with the feedback Flutter showed, shared by the list, the detail screen and menus.
struct PodcastActions {
    let app: AppModel

    var supportsFavorites: Bool {
        app.core.session.supports(feature: .favoriteEntities)
    }

    /// Picks up the episode in progress if there is one, otherwise plays from the top.
    func play(_ podcast: Podcast, shuffled: Bool = false) {
        let podcastId = podcast.id
        let currentEpisodeId = podcast.state.currentEpisodeId
        Task {
            guard let episodes = try? await app.core.playables.fetchForPodcast(podcastId: podcastId),
                  !episodes.isEmpty
            else { return }

            if !shuffled, let current = episodes.first(where: { $0.id == currentEpisodeId }) {
                app.player.controller.replaceQueue(playables: episodes, shuffle: false, autoPlay: false)
                app.player.play(current)
            } else {
                app.player.play(episodes, shuffled: shuffled)
            }
        }
    }

    func checkForNewEpisodes(_ podcast: Podcast) async {
        do {
            _ = try await app.core.playables.fetchForPodcast(podcastId: podcast.id, checkForNewEpisodes: true)
            app.toasts.show("Feed refreshed", systemImage: "arrow.clockwise")
        } catch {
            app.toasts.showError("Refresh failed")
        }
    }

    func unsubscribe(_ podcast: Podcast) {
        Task {
            do {
                try await app.core.podcasts.unsubscribe(podcast: podcast)
                app.toasts.show("Unsubscribed", systemImage: "minus.circle")
            } catch {
                app.toasts.showError(message: "Could not unsubscribe.")
            }
        }
    }

    static func addFailureMessage(httpStatus: Int?) -> String {
        httpStatus == 409
            ? "You are already subscribed to this podcast."
            : "Something wrong happened. Please try again."
    }
}

/// Context menu and toolbar items for one podcast.
struct PodcastMenu: View {
    let podcast: Podcast
    var includesPlayback = true
    let onUnsubscribe: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        let actions = PodcastActions(app: app)

        if includesPlayback {
            Section {
                Button(podcast.state.currentEpisodeId == nil ? "Play All" : "Continue", systemImage: "play.fill") {
                    actions.play(podcast)
                }
                Button("Shuffle", systemImage: "shuffle") {
                    actions.play(podcast, shuffled: true)
                }
            }
        }

        Section {
            if actions.supportsFavorites {
                EntityFavoriteButton(isFavorite: podcast.favorite) {
                    try await app.core.podcasts.toggleFavorite(podcast: podcast)
                }
            }
            Button("Refresh", systemImage: "arrow.clockwise") {
                let podcast = podcast
                Task { await actions.checkForNewEpisodes(podcast) }
            }
        }

        Button("Unsubscribe", systemImage: "minus.circle", role: .destructive, action: onUnsubscribe)
    }
}

extension View {
    func podcastUnsubscribeConfirmation(_ podcast: Binding<Podcast?>, onUnsubscribe: @escaping (Podcast) -> Void) -> some View {
        destructiveConfirmation(
            "Unsubscribe?",
            item: podcast,
            actionLabel: "Unsubscribe",
            message: { "Unsubscribe from \"\($0.title)\"?" },
            action: onUnsubscribe
        )
    }
}

struct AddPodcastSheet: View {
    @Environment(AppModel.self) private var app
    @State private var url = ""
    @FocusState private var isURLFocused: Bool

    private var trimmedURL: String { url.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        FormSheet(
            title: "Add Podcast",
            submitLabel: "Add",
            canSubmit: trimmedURL.isWebURL,
            failureMessage: { PodcastActions.addFailureMessage(httpStatus: $0.httpStatus) },
            submit: add
        ) {
            TextField("Podcast RSS URL", text: $url)
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isURLFocused)
        }
        .onAppear { isURLFocused = true }
    }

    private func add() async throws {
        _ = try await app.core.podcasts.add(url: trimmedURL)
        app.toasts.show("Podcast added")
    }
}
