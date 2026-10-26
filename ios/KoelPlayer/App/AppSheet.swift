@preconcurrency import Shared
import SwiftUI

/// Sheets that any screen can open, presented by whichever screen is in front.
enum AppSheet: Identifiable {
    case addToPlaylist([any Playable])
    case details(any Playable)
    case artistInfo(Artist)
    case playbackSettings

    var id: String {
        switch self {
        case .addToPlaylist(let playables): "add-to-playlist:" + playables.map(\.id).joined(separator: ",")
        case .details(let playable): "details:\(playable.id)"
        case .artistInfo(let artist): "artist-info:\(artist.id)"
        case .playbackSettings: "playback-settings"
        }
    }
}

extension View {
    /// Presents `AppModel.sheet`. Only the screen in front may present it: a sheet attached
    /// to a screen covered by Now Playing would not show.
    func appSheets(isFrontmost: Bool) -> some View {
        modifier(AppSheetPresenter(isFrontmost: isFrontmost))
    }
}

private struct AppSheetPresenter: ViewModifier {
    let isFrontmost: Bool

    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        content.sheet(item: sheet) { sheet in
            switch sheet {
            case .addToPlaylist(let playables):
                AddToPlaylistView(playables: playables)
            case .details(let playable):
                PlayableDetailsView(playable: playable)
            case .artistInfo(let artist):
                ArtistInfoSheet(artist: artist)
            case .playbackSettings:
                PlaybackSettingsSheet(settings: app.core.playbackSettings)
            }
        }
    }

    private var sheet: Binding<AppSheet?> {
        Binding {
            isFrontmost ? app.sheet : nil
        } set: { newValue in
            app.sheet = newValue
        }
    }
}
