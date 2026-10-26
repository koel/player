@preconcurrency import Shared
@testable import KoelPlayer
import Testing

struct EqualizerScaleTests {
    @Test func loudestGainSitsAtTheTopAndQuietestAtTheBottom() {
        #expect(EqualizerScale.y(of: 20) == 0)
        #expect(EqualizerScale.y(of: 0) == 50)
        #expect(EqualizerScale.y(of: -20) == 100)
        #expect(EqualizerScale.y(of: 8) == 30)
    }

    @Test func draggingToAPositionReadsBackItsGainInTenthsOfADecibel() {
        #expect(EqualizerScale.decibels(atY: 30) == 8)
        #expect(EqualizerScale.decibels(atY: 31.26) == 7.5)
        #expect(EqualizerScale.decibels(atY: EqualizerScale.y(of: -3.7)) == -3.7)
    }

    @Test func draggingPastTheTrackStopsAtItsEnds() {
        #expect(EqualizerScale.decibels(atY: -40) == 20)
        #expect(EqualizerScale.decibels(atY: 180) == -20)
    }
}

struct EqualizerPanelTests {
    @Test func handlesSpreadEdgeToEdgeAtTheirGains() {
        let handles = EqualizerPanel.handleCenters(gains: [20, 0, -20], width: 224)

        #expect(handles.map(\.x) == [12, 112, 212])
        #expect(handles.map(\.y) == [0, 50, 100])
    }
}
