import AVFoundation
@testable import KoelPlayer
@preconcurrency import Shared
import Testing

struct EqualizerProcessorTests {
    private static let sampleRate = 44_100.0
    private static let oneKilohertzBand: Int32 = 4

    @Test func aFlatPresetLeavesSamplesUntouched() {
        let processor = Self.preparedProcessor(Equalizer.shared.default)
        let buffer = Self.sine(frequency: 440)
        let original = Self.samples(of: buffer)

        Self.run(processor, on: buffer)

        #expect(Self.samples(of: buffer) == original)
    }

    @Test func boostingABandRaisesItsFrequencyOnly() {
        let boost = Equalizer.shared.default.withGain(band: Self.oneKilohertzBand, decibels: 6)

        #expect(abs(Self.gainInDecibels(of: boost, atFrequency: 1_000) - 6) < 0.3)
        #expect(abs(Self.gainInDecibels(of: boost, atFrequency: 100)) < 0.5)
    }

    @Test func aNegativePreampHalvesTheAmplitude() {
        let halving = Equalizer.shared.default.withPreamp(decibels: 20 * log10(0.5))

        #expect(abs(Self.gainInDecibels(of: halving, atFrequency: 440) - 20 * log10(0.5)) < 0.01)
    }

    @Test func aNewPresetTakesEffectOnTheNextBuffer() {
        let processor = Self.preparedProcessor(Equalizer.shared.default)
        let before = Self.sine(frequency: 1_000)
        Self.run(processor, on: before)

        processor.setPreset(Equalizer.shared.default.withGain(band: Self.oneKilohertzBand, decibels: 12))
        let after = Self.sine(frequency: 1_000)
        Self.run(processor, on: after)

        #expect(Self.settledRms(of: after) > Self.settledRms(of: before) * 3)
    }

    private static func gainInDecibels(of preset: EqualizerPreset, atFrequency frequency: Double) -> Double {
        let buffer = sine(frequency: frequency)
        let rmsBefore = settledRms(of: buffer)
        run(preparedProcessor(preset), on: buffer)
        return 20 * log10(settledRms(of: buffer) / rmsBefore)
    }

    private static func preparedProcessor(_ preset: EqualizerPreset) -> EqualizerProcessor {
        let processor = EqualizerProcessor(preset: preset)
        processor.prepare(sampleRate: sampleRate, channelCount: 1)
        return processor
    }

    private static func run(_ processor: EqualizerProcessor, on buffer: AVAudioPCMBuffer) {
        processor.process(UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList), frameCount: Int(buffer.frameLength))
    }

    private static func sine(frequency: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frames = AVAudioFrameCount(sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        for frame in 0..<Int(frames) {
            buffer.floatChannelData![0][frame] = Float(sin(Double(frame) * 2 * .pi * frequency / sampleRate) * 0.1)
        }
        return buffer
    }

    private static func samples(of buffer: AVAudioPCMBuffer) -> [Float] {
        Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
    }

    /// Skips the first half, where the filters are still settling.
    private static func settledRms(of buffer: AVAudioPCMBuffer) -> Double {
        let settled = samples(of: buffer).dropFirst(Int(buffer.frameLength) / 2)
        return sqrt(settled.reduce(0) { $0 + Double($1 * $1) } / Double(settled.count))
    }
}
