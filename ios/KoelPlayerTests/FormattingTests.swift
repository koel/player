import Foundation
@testable import KoelPlayer
import Testing

struct FormattingTests {
    @Test func formatsPlaybackTimes() {
        #expect(187.4.playbackTime == "3:07")
        #expect(0.0.playbackTime == "0:00")
        #expect(3723.0.playbackTime == "1:02:03")
        #expect(Double.nan.playbackTime == "0:00")
    }

    @Test func parsesKoelTimestamps() {
        #expect("2024-01-02T03:04:05Z".iso8601Date != nil)
        #expect("2024-01-02T03:04:05.000000Z".iso8601Date != nil)
        #expect("not a date".iso8601Date == nil)
    }

    @Test func pluralizes() {
        #expect(1.pluralized("song") == "1 song")
        #expect(3.pluralized("song") == "3 songs")
        #expect(2.pluralized("episode") == "2 episodes")
    }

    @Test func showsOldEpisodeDatesInFull() {
        let old = Date.now.addingTimeInterval(-400 * 24 * 3600)
        let recent = Date.now.addingTimeInterval(-2 * 24 * 3600)

        #expect(old.episodeDateLabel == old.formatted(date: .abbreviated, time: .omitted))
        #expect(recent.episodeDateLabel != recent.formatted(date: .abbreviated, time: .omitted))
    }
}
