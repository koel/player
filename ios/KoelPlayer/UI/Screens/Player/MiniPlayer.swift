@preconcurrency import Shared
import SwiftUI

/// Lives in the tab bar's bottom accessory, like Apple Music's mini player.
struct MiniPlayer: View {
    @Environment(AppModel.self) private var app
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        let state = app.player.state

        HStack(spacing: 12) {
            artwork(state)

            VStack(alignment: .leading, spacing: 0) {
                Text(title(state))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if let subtitle = subtitle(state) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                app.player.togglePlayPause()
            } label: {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

            if placement != .inline, !state.isRadioMode {
                Button {
                    app.player.skipToNext()
                } label: {
                    Image(systemName: "forward.fill").frame(width: 32, height: 32)
                }
                .accessibilityLabel("Next")
            }
        }
        .font(.title3)
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .contentShape(.rect)
        .onTapGesture { app.isNowPlayingPresented = true }
        .accessibilityAction(named: "Open Now Playing") { app.isNowPlayingPresented = true }
    }

    private func artwork(_ state: PlaybackState) -> some View {
        Artwork(url: state.radioStation?.logo ?? state.current?.artworkUrl, size: 30, cornerRadius: 6)
            .overlay {
                if state.hasFailed {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .frame(width: 30, height: 30)
                        .background(.black.opacity(0.55), in: .rect(cornerRadius: 6))
                        .accessibilityLabel("Couldn't play this item")
                } else if state.isBuffering {
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: 30, height: 30)
                        .background(.black.opacity(0.55), in: .rect(cornerRadius: 6))
                }
            }
    }

    private func title(_ state: PlaybackState) -> String {
        if let station = state.radioStation { return state.radioStreamTitle ?? station.name }
        return state.current?.title ?? ""
    }

    private func subtitle(_ state: PlaybackState) -> String? {
        if let station = state.radioStation {
            return state.isBuffering ? "Connecting…" : (state.radioStreamTitle == nil ? nil : station.name)
        }
        return state.current?.subtitle
    }
}
