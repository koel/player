import AVFoundation
import os
@preconcurrency import Shared

/// Runs the equalizer's preamp and filters over float PCM on the audio thread. A new preset can
/// arrive from any other thread; the audio thread picks it up on its next buffer without waiting
/// for a lock or allocating memory.
nonisolated final class EqualizerProcessor: @unchecked Sendable {
    private static let filterCount = Equalizer.shared.frequencies.count

    private let lock = OSAllocatedUnfairLock()
    private var preset: EqualizerPreset
    private var sampleRate: Double?
    private let pending = Coefficients()
    private var pendingVersion = 0

    private let active = Coefficients()
    private var activeVersion = 0
    private var filterState = UnsafeMutableBufferPointer<Double>(start: nil, count: 0)
    private var channelCount = 0

    init(preset: EqualizerPreset) {
        self.preset = preset
    }

    deinit {
        filterState.deallocate()
    }

    func setPreset(_ preset: EqualizerPreset) {
        lock.withLockUnchecked {
            self.preset = preset
            publishCoefficients()
        }
    }

    /// Must not overlap `process`; an audio tap guarantees that.
    func prepare(sampleRate: Double, channelCount: Int) {
        filterState.deallocate()
        filterState = .allocate(capacity: channelCount * Self.filterCount * Biquad.stateSize)
        filterState.initialize(repeating: 0)
        self.channelCount = channelCount

        lock.withLockUnchecked {
            self.sampleRate = sampleRate
            publishCoefficients()
        }
    }

    /// Filters `frameCount` frames in place. Buffers may be interleaved or not.
    func process(_ buffers: UnsafeMutableAudioBufferListPointer, frameCount: Int) {
        adoptPublishedCoefficients()
        guard !active.isFlat else { return }

        var firstChannel = 0
        for buffer in buffers {
            let interleavedChannels = Int(buffer.mNumberChannels)
            defer { firstChannel += interleavedChannels }
            guard interleavedChannels > 0, let samples = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }

            let framesInBuffer = min(frameCount, Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * interleavedChannels))
            for offset in 0..<interleavedChannels where firstChannel + offset < channelCount {
                filter(samples + offset, stride: interleavedChannels, frameCount: framesInBuffer, channel: firstChannel + offset)
            }
        }
    }

    /// Runs on whichever thread holds the lock, never the audio thread.
    private func publishCoefficients() {
        guard let sampleRate else { return }
        for (band, biquad) in Equalizer.shared.filters(preset: preset, sampleRate: sampleRate).enumerated() {
            pending.store(biquad, band: band)
        }
        pending.gain = Equalizer.shared.preampGain(preset: preset)
        pending.isFlat = preset.isFlat
        pendingVersion += 1
    }

    private func adoptPublishedCoefficients() {
        lock.withLockIfAvailableUnchecked {
            guard pendingVersion != activeVersion else { return }
            active.copy(from: pending)
            activeVersion = pendingVersion
        }
    }

    private func filter(_ samples: UnsafeMutablePointer<Float>, stride: Int, frameCount: Int, channel: Int) {
        guard let states = filterState.baseAddress, let coefficients = active.filters.baseAddress else { return }
        let channelStates = states + channel * Self.filterCount * Biquad.stateSize
        let gain = active.gain

        for frame in 0..<frameCount {
            var sample = Double(samples[frame * stride]) * gain
            for band in 0..<Self.filterCount {
                let biquad = coefficients + band * Biquad.coefficientCount
                let state = channelStates + band * Biquad.stateSize
                let output = biquad[0] * sample + state[0]
                state[0] = biquad[1] * sample - biquad[3] * output + state[1]
                state[1] = biquad[2] * sample - biquad[4] * output
                sample = output
            }
            samples[frame * stride] = Float(sample)
        }
    }
}

/// The preamp and filters, in memory allocated once so the audio thread can copy them freely.
private nonisolated final class Coefficients {
    let filters = UnsafeMutableBufferPointer<Double>.allocate(capacity: Equalizer.shared.frequencies.count * Biquad.coefficientCount)
    var gain = 1.0
    var isFlat = true

    init() {
        filters.initialize(repeating: 0)
    }

    deinit {
        filters.deallocate()
    }

    func store(_ biquad: Biquad, band: Int) {
        let start = band * Biquad.coefficientCount
        filters[start] = biquad.b0
        filters[start + 1] = biquad.b1
        filters[start + 2] = biquad.b2
        filters[start + 3] = biquad.a1
        filters[start + 4] = biquad.a2
    }

    func copy(from other: Coefficients) {
        _ = filters.update(fromContentsOf: other.filters)
        gain = other.gain
        isFlat = other.isFlat
    }
}

private nonisolated extension Biquad {
    /// b0, b1, b2, a1, a2.
    static let coefficientCount = 5
    /// Two delayed values per filter, in transposed direct form II.
    static let stateSize = 2
}
