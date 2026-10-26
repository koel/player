@preconcurrency import Shared
import SwiftUI

/// Lyrics plus artist and album information for songs; the description for episodes.
struct PlayableDetailsView: View {
    let playable: any Playable

    private enum Pane: String, CaseIterable, Identifiable {
        case lyrics = "Lyrics"
        case artist = "Artist"
        case album = "Album"

        var id: Self { self }
    }

    @State private var pane = Pane.lyrics

    var body: some View {
        NavigationStack {
            Group {
                if let song = playable as? Song {
                    VStack(spacing: 0) {
                        Picker("Details", selection: $pane) {
                            ForEach(Pane.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        switch pane {
                        case .lyrics: LyricsPane(song: song)
                        case .artist: ArtistBiography(artistId: song.artistId)
                        case .album: AlbumInfoPane(song: song)
                        }
                    }
                } else if let episode = playable as? Episode {
                    ScrollView {
                        HTMLText(html: episode.description_)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle(playable.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(uiColor: .systemBackground))
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

    var body: some View {
        let currentIndex = isCurrent ? Int(Lyrics.shared.currentLineIndex(lines: lines, position: app.player.position)) : -1

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Button {
                            if isCurrent { app.player.seek(to: line.time) }
                        } label: {
                            Text(line.text)
                                .font(.title3.bold())
                                .foregroundStyle(index == currentIndex ? .primary : .tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
