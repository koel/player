import Foundation
@testable import KoelPlayer
import Testing

struct WidgetLinkTests {
    @Test func nowPlayingSurvivesTheRoundTrip() {
        #expect(WidgetLink(url: WidgetLink.nowPlaying.url) == .nowPlaying)
    }

    @Test func recentItemKeepsItsId() {
        let link = WidgetLink.playRecent(id: "01a0e346-2b59-7017-90de-1ae845743999")

        #expect(WidgetLink(url: link.url) == link)
    }

    @Test func ignoresOtherLinks() {
        #expect(WidgetLink(url: URL(string: "https://koel.dev/recent/1")!) == nil)
        #expect(WidgetLink(url: URL(string: "koelplayer://elsewhere")!) == nil)
        #expect(WidgetLink(url: URL(string: "koelplayer://recent")!) == nil)
    }
}

struct WidgetSnapshotTests {
    @Test func survivesEncoding() throws {
        let snapshot = WidgetSnapshot(
            nowPlaying: .init(title: "abcdefu", subtitle: "GAYLE", isPlaying: true, isRadio: false, artworkFile: "cover.jpg"),
            recentlyPlayed: [.init(id: "1", title: "Song", subtitle: "Artist", artworkFile: nil)]
        )

        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: JSONEncoder().encode(snapshot))

        #expect(decoded == snapshot)
    }

    @Test func artworkFilesAreStablePerCover() {
        let cover = WidgetPublisher.artworkFile(for: "https://example.com/covers/a.jpg")

        #expect(cover == WidgetPublisher.artworkFile(for: "https://example.com/covers/a.jpg"))
        #expect(cover != WidgetPublisher.artworkFile(for: "https://example.com/covers/b.jpg"))
        #expect(cover?.hasSuffix(".jpg") == true)
    }

    @Test func noArtworkFileWithoutACover() {
        #expect(WidgetPublisher.artworkFile(for: nil) == nil)
        #expect(WidgetPublisher.artworkFile(for: "") == nil)
    }
}
