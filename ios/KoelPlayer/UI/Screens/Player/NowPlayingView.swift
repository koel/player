import AVKit
import MediaPlayer
@preconcurrency import Shared
import SwiftUI

struct NowPlayingView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.brandColor) private var brandColor

    /// How much of the queue's heading shows below the player, hinting that it scrolls.
    private static let queuePeek: CGFloat = 56
    private static let maxArtworkSize: CGFloat = 320

    var body: some View {
        let state = app.player.state

        GeometryReader { proxy in
            NowPlayingScroller(
                queue: state.queue,
                playerHeight: state.queue.isEmpty ? proxy.size.height : proxy.size.height - Self.queuePeek,
                player: { player(state) },
                heading: { QueueHeading() },
                onMove: { from, to in app.player.controller.move(from: Int32(from), to: Int32(to)) },
                onRemove: { app.player.removeFromQueue($0) }
            )
        }
        .background { blurredBackground(state) }
        .appSheets(isFrontmost: true)
        .modifier(ToastOverlay(toasts: app.toasts))
        .onChange(of: state.hasFailed) { _, hasFailed in
            if hasFailed { app.toasts.showError("Couldn't play this item") }
        }
        .onChange(of: app.player.hasSomethingToShow) { _, hasSomething in
            if !hasSomething { dismiss() }
        }
    }

    private func player(_ state: PlaybackState) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .accessibilityHidden(true)

            Spacer(minLength: 16)

            artwork(state)

            Spacer(minLength: 24)

            titleRow(state)
                .padding(.bottom, 20)

            if state.isRadioMode {
                Label("Live", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
            } else if let current = state.current {
                PlaybackProgress(current: current)
                    .padding(.bottom, 16)
            }

            transportControls(state)
                .padding(.bottom, 24)

            SystemVolumeSlider()
                .frame(height: 34)
                .padding(.bottom, 16)

            bottomBar(state)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
    }

    /// Full size where it fits, smaller on short screens so the controls below stay on screen.
    private func artwork(_ state: PlaybackState) -> some View {
        GeometryReader { proxy in
            let size = min(proxy.size.height, Self.maxArtworkSize)
            Group {
                if state.isRadioMode {
                    Artwork(url: artworkUrl(state), size: size, cornerRadius: 14)
                        .shadow(color: .black.opacity(0.5), radius: 30, y: 16)
                        .scaleEffect(state.isPlaying ? 1 : 0.86)
                        .animation(.spring(duration: 0.45, bounce: 0.3), value: state.isPlaying)
                } else {
                    QueueArtworkCarousel(state: state, artworkSize: size)
                        .padding(.horizontal, -28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: Self.maxArtworkSize)
        .layoutPriority(1)
    }

    private func artworkUrl(_ state: PlaybackState) -> String? {
        state.radioStation?.logo ?? state.current?.artworkUrl
    }

    @ViewBuilder
    private func titleRow(_ state: PlaybackState) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if let station = state.radioStation {
                    MarqueeText(text: state.radioStreamTitle ?? station.name)
                        .font(.title3.bold())
                    if state.radioStreamTitle != nil {
                        MarqueeText(text: station.name).foregroundStyle(.secondary)
                    }
                } else if let current = state.current {
                    MarqueeText(text: current.title)
                        .font(.title3.bold())
                    Button { goToArtist(current) } label: {
                        MarqueeText(text: current.subtitle)
                    }
                    .foregroundStyle(.secondary)
                    .disabled(app.isOffline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let current = state.current, !state.isRadioMode {
                Button {
                    PlayableActions(app: app).toggleFavorite(current)
                } label: {
                    Image(systemName: current.favorite ? "heart.fill" : "heart")
                        .contentTransition(.symbolEffect(.replace))
                }
                .foregroundStyle(current.favorite ? brandColor : .primary)
                .disabled(app.isOffline)
                .accessibilityLabel(current.favorite ? "Undo Favorite" : "Favorite")

                DownloadButton(playable: current)

                Menu {
                    PlayableMenu(playable: current)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .font(.title2)
        .buttonStyle(.plain)
    }

    private func transportControls(_ state: PlaybackState) -> some View {
        HStack {
            if !state.isRadioMode {
                Button { app.player.skipToPrevious() } label: {
                    Image(systemName: "backward.fill")
                }
                .accessibilityLabel("Previous")
                Spacer()
            }

            Button { app.player.togglePlayPause() } label: {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 36))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 84, height: 84)
                    .glassEffect(.clear.interactive(), in: .circle)
            }
            .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

            if !state.isRadioMode {
                Spacer()
                Button { app.player.skipToNext() } label: {
                    Image(systemName: "forward.fill")
                }
                .accessibilityLabel("Next")
            }
        }
        .font(.system(size: 34))
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func bottomBar(_ state: PlaybackState) -> some View {
        HStack {
            if let current = state.current, !state.isRadioMode {
                Button { app.sheet = .details(current) } label: {
                    Image(systemName: "quote.bubble")
                }
                .accessibilityLabel("Lyrics and Details")
            } else {
                Color.clear.frame(width: 28)
            }

            Spacer()
            AirPlayButton().frame(width: 44, height: 44)
            Spacer()
            Button { app.sheet = .playbackSettings } label: {
                Image(systemName: "slider.vertical.3")
            }
            .accessibilityLabel("Playback settings")
            Spacer()

            if !state.isRadioMode {
                Button { app.player.rotateRepeatMode() } label: {
                    Image(systemName: state.repeatMode == .one ? "repeat.1" : "repeat")
                        .foregroundStyle(state.repeatMode == .none ? Color.secondary : brandColor)
                }
                .accessibilityLabel("Repeat: \(state.repeatMode.label)")
            }
        }
        .font(.title3)
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private func blurredBackground(_ state: PlaybackState) -> some View {
        CoverBackdrop(url: artworkUrl(state))
    }

    private func goToArtist(_ playable: any Playable) {
        if let song = playable as? Song {
            app.open(.artist(id: song.artistId))
        } else if let episode = playable as? Episode {
            app.open(.podcast(id: episode.podcastId))
        }
    }
}

/// The scrubber and times. Its own view, so the position ticking along redraws only this and not the queue below.
private struct PlaybackProgress: View {
    let current: any Playable

    @Environment(AppModel.self) private var app
    @State private var scrubPosition: Double?
    @State private var waveform: [Double] = []

    var body: some View {
        let position = scrubPosition ?? app.player.position
        let length = max(current.length, 1)

        VStack(spacing: 4) {
            PlaybackScrubber(position: min(position, length), length: length, waveform: waveform, isPlaying: app.player.state.isPlaying) { target in
                scrubPosition = target
            } onCommit: { target in
                app.player.seek(to: target)
                scrubPosition = nil
            }

            HStack {
                Text(position.playbackTime)
                Spacer()
                Text("-" + max(length - position, 0).playbackTime)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .task(id: current.id) { await loadWaveform() }
    }

    private func loadWaveform() async {
        waveform = []
        guard current is Song else { return }
        waveform = ((try? await app.core.mediaInfo.fetchWaveform(songId: current.id)) ?? []).map(\.doubleValue)
    }
}

private struct QueueHeading: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        SectionHeader(title: "Queued", action: SectionHeader.Action(title: "Clear", role: .destructive) {
            app.player.controller.clearQueue()
        })
    }
}

extension RepeatMode {
    var label: String {
        switch self {
        case .all: "All"
        case .one: "One"
        default: "Off"
        }
    }
}

/// The system volume slider, which also follows AirPlay and Bluetooth devices.
private struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.showsVolumeSlider = true
        return view
    }

    func updateUIView(_ view: MPVolumeView, context: Context) {}
}

private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .secondaryLabel
        picker.prioritizesVideoDevices = false
        return picker
    }

    func updateUIView(_ view: AVRoutePickerView, context: Context) {}
}

/// The cover, blurred across the whole screen. Drawn larger than the screen so the blur's
/// faded edges stay off screen.
private struct CoverBackdrop: View {
    let url: String?

    @State private var image: UIImage?

    var body: some View {
        Color.black
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.6)
                        .blur(radius: 70)
                        .transition(.opacity)
                }
            }
            .overlay(.black.opacity(0.4))
            .clipped()
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: image)
            .task(id: url) {
                guard let remote = url.flatMap(URL.init(string:)) else { image = nil; return }
                image = await ImagePipeline.shared.image(for: remote, pointSize: 200)
            }
    }
}
