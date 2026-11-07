@testable import KoelPlayer
import SwiftUI
import Testing

struct BrandMeshBackgroundTests {
    @Test func driftsOnlyWhileTheAppIsActive() {
        #expect(!BrandMeshBackground.isPaused(reduceMotion: false, scenePhase: .active))
        #expect(BrandMeshBackground.isPaused(reduceMotion: false, scenePhase: .inactive))
        #expect(BrandMeshBackground.isPaused(reduceMotion: false, scenePhase: .background))
    }

    @Test func staysStillWithReduceMotion() {
        #expect(BrandMeshBackground.isPaused(reduceMotion: true, scenePhase: .active))
    }
}
