import AVKit
import MediaPlayer
@preconcurrency import Shared
import SwiftUI

struct NowPlayingView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.brandColor) private var brandColor

    @State private var isQueuePresented = false
    @State private var scrubPosition: Double?

    var body: some View {
        let state = app.player.state

        VStack(spacing: 0) {
            Capsule()
                .fill(.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .accessibilityHidden(true)

            Spacer(minLength: 16)

            Artwork(url: artworkUrl(state), size: 320, cornerRadius: 14)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 16)
                .scaleEffect(state.isPlaying ? 1 : 0.86)
                .animation(.spring(duration: 0.45, bounce: 0.3), value: state.isPlaying)

            Spacer(minLength: 24)

            titleRow(state)
                .padding(.bottom, 20)

            if state.isRadioMode {
                Label("Live", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
            } else if let current = state.current {
                progress(for: current)
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
        .background { blurredBackground(state) }
        .sheet(isPresented: $isQueuePresented) {
            QueueView()
                .presentationDetents([.medium, .large])
        }
        .onChange(of: app.player.hasSomethingToShow) { _, hasSomething in
            if !hasSomething { dismiss() }
        }
    }

    private func artworkUrl(_ state: PlaybackState) -> String? {
        state.radioStation?.logo ?? state.current?.artworkUrl
    }

    @ViewBuilder
    private func titleRow(_ state: PlaybackState) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if let station = state.radioStation {
                    Text(state.radioStreamTitle ?? station.name)
                        .font(.title3.bold())
                    if state.radioStreamTitle != nil {
                        Text(station.name).foregroundStyle(.secondary)
                    }
                } else if let current = state.current {
                    Text(current.title)
                        .font(.title3.bold())
                    Button(current.subtitle) { goToArtist(current) }
                        .foregroundStyle(.secondary)
                        .disabled(app.isOffline)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let current = state.current, !state.isRadioMode {
                Button {
                    PlayableActions(app: app).toggleFavorite(current)
                } label: {
                    Image(systemName: current.favorite ? "star.fill" : "star")
                        .contentTransition(.symbolEffect(.replace))
                }
                .foregroundStyle(current.favorite ? brandColor : .primary)
                .disabled(app.isOffline)
                .accessibilityLabel(current.favorite ? "Undo Favorite" : "Favorite")

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

    private func progress(for current: any Playable) -> some View {
        let position = scrubPosition ?? app.player.position
        let length = max(current.length, 1)

        return VStack(spacing: 4) {
            PlaybackScrubber(position: min(position, length), length: length) { target in
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
                    .font(.system(size: 52))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 72, height: 72)
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
        .overlay {
            if state.hasFailed {
                Label("Couldn't play this item", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 52)
            }
        }
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

            if !state.isRadioMode {
                Button { app.player.rotateRepeatMode() } label: {
                    Image(systemName: state.repeatMode == .one ? "repeat.1" : "repeat")
                        .foregroundStyle(state.repeatMode == .none ? Color.secondary : brandColor)
                }
                .accessibilityLabel("Repeat: \(state.repeatMode.label)")
                Spacer()

                Button { isQueuePresented = true } label: {
                    Image(systemName: "list.bullet")
                }
                .accessibilityLabel("Queue")
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
        dismiss()
        if let song = playable as? Song {
            app.navigator.push(.artist(id: song.artistId))
        } else if let episode = playable as? Episode {
            app.navigator.push(.podcast(id: episode.podcastId))
        }
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
