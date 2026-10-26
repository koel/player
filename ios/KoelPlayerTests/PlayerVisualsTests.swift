import AVFoundation
@testable import KoelPlayer
import SwiftUI
import Testing

struct WaveformTests {
    @Test func eachBarTakesTheLoudestSliceItCovers() {
        #expect(WaveformBars.resampled([0.1, 0.9, 0.2, 0.3], to: 2) == [0.9, 0.3])
    }

    @Test func barsOutnumberingLevelsRepeatThem() {
        #expect(WaveformBars.resampled([0.2, 0.8], to: 4) == [0.2, 0.2, 0.8, 0.8])
    }

    @Test func silenceStaysFlat() {
        #expect(WaveformBars.resampled([], to: 3) == [0, 0, 0])
        #expect(WaveformBars.normalized([0, 0, 0]) == [0, 0, 0])
    }

    @Test func narrowLoudnessRangeIsStretchedToTheFullHeight() {
        let levels = WaveformBars.normalized([0.6, 0.62, 0.65, 0.7, 0.8, 0.9, 0.95, 1.0, 0.6, 0.6])

        #expect(levels.max() == 1)
        #expect(levels.min()! < 0.15)
        #expect(levels[3] < levels[4])
    }

    @Test func glowIsBrightestAtThePlayheadAndOnlyBehindIt() {
        #expect(WaveformBars.glow(atDistance: 0) == 1)
        #expect(WaveformBars.glow(atDistance: 5) == 0)
        #expect(WaveformBars.glow(atDistance: -WaveformBars.glowRadius) < 0.001)
        #expect(WaveformBars.glow(atDistance: -WaveformBars.glowRadius / 2) > 0.4)
    }

    @Test func barsRiseLeftToRight() {
        let first = WaveformBars.rise(of: 0, among: 100, growth: 0.5)
        let last = WaveformBars.rise(of: 99, among: 100, growth: 0.5)

        #expect(first > last)
        #expect(WaveformBars.rise(of: 99, among: 100, growth: 1) == 1)
        #expect(WaveformBars.rise(of: 0, among: 100, growth: 0) == 0)
    }
}

struct MarqueeTests {
    @Test func holdsStillBeforeScrolling() {
        #expect(MarqueeText.offset(elapsed: 0, textWidth: 300) == 0)
        #expect(MarqueeText.offset(elapsed: MarqueeText.pause - 0.1, textWidth: 300) == 0)
    }

    @Test func scrollsAtASteadySpeed() {
        let offset = MarqueeText.offset(elapsed: MarqueeText.pause + 1, textWidth: 300)

        #expect(abs(offset + MarqueeText.pointsPerSecond) < 0.001)
    }

    @Test func startsOverOnceTheTextHasScrolledPast() {
        let cycle = MarqueeText.pause + (300 + MarqueeText.gap) / MarqueeText.pointsPerSecond

        #expect(MarqueeText.offset(elapsed: cycle + 0.5, textWidth: 300) == 0)
    }

    @MainActor @Test func longTextStaysInsideItsColumn() async throws {
        let columnWidth: CGFloat = 100
        let screen = HStack(spacing: 0) {
            MarqueeText(text: "A song title far too long to fit in its column")
                .frame(width: columnWidth)
            Color.clear
        }
        .foregroundStyle(.white)
        .background(.black)
        .ignoresSafeArea()
        let window = try #require((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow)
        let host = UIHostingController(rootView: screen)
        host.view.frame = CGRect(x: 0, y: 200, width: 400, height: 40)
        window.addSubview(host.view)
        defer { host.view.removeFromSuperview() }
        try await Task.sleep(for: .milliseconds(500))

        let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }

        #expect(Self.hasBrightPixels(in: image, xRange: 0..<columnWidth))
        #expect(!Self.hasBrightPixels(in: image, xRange: columnWidth + 4..<400))
    }

    private static func hasBrightPixels(in image: UIImage, xRange: Range<CGFloat>) -> Bool {
        guard let cgImage = image.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return false }
        let scale = image.scale
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        for y in 0..<cgImage.height {
            for x in Int(xRange.lowerBound * scale)..<min(Int(xRange.upperBound * scale), cgImage.width) {
                let pixel = y * cgImage.bytesPerRow + x * bytesPerPixel
                if bytes[pixel] > 128 || bytes[pixel + 1] > 128 || bytes[pixel + 2] > 128 { return true }
            }
        }
        return false
    }
}

struct AlphabetIndexBarTests {
    @Test func picksTheLetterUnderTheFinger() {
        #expect(AlphabetIndexBar.letterIndex(at: 0, letterCount: 5) == 0)
        #expect(AlphabetIndexBar.letterIndex(at: 31, letterCount: 5) == 2)
    }

    @Test func holdsAtTheEndsWhenSlidingPastThem() {
        #expect(AlphabetIndexBar.letterIndex(at: -40, letterCount: 5) == 0)
        #expect(AlphabetIndexBar.letterIndex(at: 900, letterCount: 5) == 4)
    }

    @Test func nothingToPickWithoutLetters() {
        #expect(AlphabetIndexBar.letterIndex(at: 10, letterCount: 0) == nil)
    }
}

struct CoverColorTests {
    @Test func grayCoversLeaveTheScreenNeutral() {
        #expect(CoverColor.legibleTint(from: UIColor(white: 0.5, alpha: 1)) == nil)
    }

    @Test func colorfulCoversKeepTheirHueAtAReadableBrightness() throws {
        let tint = try #require(CoverColor.legibleTint(from: UIColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1)))
        var hue: CGFloat = 0
        tint.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)

        #expect(hue < 0.05 || hue > 0.95)
        #expect(abs(CoverColor.luminance(of: tint) - 0.18) < 0.01)
    }

    @MainActor
    @Test func fadeEndsOnTheNewColor() async {
        var applied: [Color?] = []

        await CoverColor.fade(from: nil, to: .red) { applied.append($0) }

        #expect(applied.count > 10)
        #expect(applied.first != .red)
        #expect(applied.last == .red)
    }
}

struct InterruptionTests {
    private func interruptionEnded(shouldResume: Bool) -> Notification {
        Notification(name: AVAudioSession.interruptionNotification, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
            AVAudioSessionInterruptionOptionKey: shouldResume ? AVAudioSession.InterruptionOptions.shouldResume.rawValue : 0,
        ])
    }

    @Test func resumesWhenTheSystemAllowsAndMusicWasPlaying() {
        #expect(SystemMediaControls.shouldResume(after: interruptionEnded(shouldResume: true), wasPlaying: true))
    }

    @Test func staysPausedIfItWasPausedBefore() {
        #expect(!SystemMediaControls.shouldResume(after: interruptionEnded(shouldResume: true), wasPlaying: false))
    }

    @Test func staysPausedWhenTheSystemSaysNotToResume() {
        #expect(!SystemMediaControls.shouldResume(after: interruptionEnded(shouldResume: false), wasPlaying: true))
    }
}

@MainActor
struct NowPlayingScrollerTests {
    @Test func noEdgeLineUnderTheStatusBar() {
        let collectionView = NowPlayingScroller<EmptyView, EmptyView>.makeCollectionView(layout: UICollectionViewFlowLayout())

        #expect(collectionView.topEdgeEffect.isHidden)
    }
}
