@testable import KoelPlayer
import Testing

@MainActor
struct QuickActionsTests {
    private let everyAction: [QuickActions.Action] = [
        .shortcut(.search), .shortcut(.playFavorites), .shortcut(.playDownloaded), .shortcut(.playRecent),
        .widget(.nowPlaying), .widget(.playRecent(id: "song")),
    ]

    @Test func waitsForTheLaunchToFinish() {
        for action in everyAction {
            #expect(QuickActions.readiness(of: action, in: .launching) == .afterLaunch)
            #expect(QuickActions.readiness(of: action, in: .loading) == .afterLaunch)
        }
    }

    @Test func runsEverythingOnceTheLibraryIsUp() {
        for action in everyAction {
            #expect(QuickActions.readiness(of: action, in: .main) == .now)
        }
    }

    @Test func playsDownloadsAndShowsNowPlayingWithoutAConnection() {
        for phase in [AppModel.Phase.noConnection, .offline] {
            #expect(QuickActions.readiness(of: .shortcut(.playDownloaded), in: phase) == .now)
            #expect(QuickActions.readiness(of: .widget(.nowPlaying), in: phase) == .now)
        }
    }

    @Test func dropsWhatNeedsTheServerWhenItIsOutOfReach() {
        for phase in [AppModel.Phase.noConnection, .offline, .login] {
            #expect(QuickActions.readiness(of: .shortcut(.playFavorites), in: phase) == .never)
            #expect(QuickActions.readiness(of: .widget(.playRecent(id: "song")), in: phase) == .never)
        }
        #expect(QuickActions.readiness(of: .shortcut(.playDownloaded), in: .login) == .never)
    }
}
