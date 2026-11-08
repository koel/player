@preconcurrency import Shared
import SwiftUI

/// Lyrics plus artist and album information for songs; the description for episodes.
struct PlayableDetailsView: View {
    let playable: any Playable

    private enum Pane: String, CaseIterable {
        case lyrics = "Lyrics"
        case artist = "Artist"
        case album = "Album"
    }

    @State private var pane = Pane.lyrics

    var body: some View {
        VStack(spacing: 0) {
            PlayableDetailsHeader(playable: playable)

            if let song = playable as? Song {
                SegmentedTabs(options: Pane.allCases, selection: $pane, title: \.rawValue)
                    .padding()

                switch pane {
                case .lyrics: LyricsPane(song: song)
                case .artist: ArtistBiography(artistId: song.artistId)
                case .album: AlbumInfoPane(song: song)
                }
            } else if let episode = playable as? Episode {
                ScrollView {
                    HTMLText(html: episode.description_)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(uiColor: .systemBackground))
    }
}

/// The cover with the title and artist beside it, like Apple Music's sheets.
private struct PlayableDetailsHeader: View {
    let playable: any Playable

    var body: some View {
        HStack(spacing: 12) {
            Artwork(url: playable.artworkUrl, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(playable.title)
                    .font(.headline)
                Text(playable.subtitle)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .padding(.horizontal)
        .padding(.top, 28)
    }
}

private struct LyricsPane: View {
    let song: Song

    @Environment(AppModel.self) private var app

    var body: some View {
        if song.lyrics.isBlank {
            ContentUnavailableView("No lyrics available.", systemImage: "quote.bubble")
        } else if Lyrics.shared.isSynced(lyrics: song.lyrics) {
            SyncedLyrics(lines: Lyrics.shared.parseSynced(lyrics: song.lyrics), isCurrent: app.player.isCurrent(song))
        } else {
            ScrollView {
                HTMLText(html: song.lyrics.replacingOccurrences(of: "\n", with: "<br>"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
}

private struct SyncedLyrics: View {
    let lines: [LyricLine]
    let isCurrent: Bool

    @Environment(AppModel.self) private var app
    @Environment(\.brandColor) private var brandColor

    var body: some View {
        let currentIndex = isCurrent ? Int(Lyrics.shared.currentLineIndex(lines: lines, position: app.player.position)) : -1

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        let look = Lyrics.shared.lineLook(index: Int32(index), currentIndex: Int32(currentIndex))
                        Button {
                            if isCurrent { app.player.seek(to: line.time) }
                        } label: {
                            Text(line.text)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(index == currentIndex ? brandColor : .white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .scaleEffect(look.scale, anchor: .leading)
                                .opacity(look.opacity)
                                .blur(radius: look.blur)
                                .animation(.easeInOut(duration: 0.45), value: currentIndex)
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: currentIndex) { _, index in
                guard index >= 0 else { return }
                withAnimation(.easeInOut) { proxy.scrollTo(index, anchor: .center) }
            }
        }
    }
}

/// The artist's biography, in the song details and the artist's Info sheet.
struct ArtistBiography: View {
    let artistId: String

    @Environment(AppModel.self) private var app
    @State private var biography: String?
    @State private var hasFailed = false

    var body: some View {
        InfoScroll(isLoading: biography == nil && !hasFailed, isEmpty: biography?.plainText.isBlank ?? hasFailed, emptyTitle: "No artist information available.") {
            HTMLText(html: biography ?? "")
        }
        .task(id: artistId) {
            do {
                biography = try await app.core.mediaInfo.fetchForArtist(artistId: artistId).biography
            } catch {
                hasFailed = true
            }
        }
    }
}

private struct AlbumInfoPane: View {
    let song: Song

    @Environment(AppModel.self) private var app
    @State private var info: AlbumInfo?
    @State private var hasFailed = false

    var body: some View {
        InfoScroll(isLoading: info == nil && !hasFailed, isEmpty: info.map { $0.information.isBlank && $0.tracks.isEmpty } ?? hasFailed, emptyTitle: "No album information available.") {
            if let info {
                VStack(alignment: .leading, spacing: 20) {
                    if !info.information.isBlank {
                        HTMLText(html: info.information)
                    }
                    if !info.tracks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tracks").font(.headline)
                            ForEach(Array(info.tracks.enumerated()), id: \.offset) { index, track in
                                HStack {
                                    Text("\(index + 1)").monospacedDigit().foregroundStyle(.secondary)
                                    Text(track.title)
                                    Spacer()
                                    Text(Double(track.length).playbackTime).monospacedDigit().foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .task(id: song.albumId) {
            do {
                info = try await app.core.mediaInfo.fetchForAlbum(albumId: song.albumId)
            } catch {
                hasFailed = true
            }
        }
    }
}

private struct InfoScroll<Content: View>: View {
    let isLoading: Bool
    let isEmpty: Bool
    let emptyTitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isLoading {
            ProgressView().frame(maxHeight: .infinity)
        } else if isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: "info.circle")
        } else {
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
}
