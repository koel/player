import AVFoundation
import MediaToolbox

/// Routes an item's decoded audio through an `EqualizerProcessor`, by way of an audio mix.
nonisolated enum EqualizerTap {
    static func audioMix(for track: AVAssetTrack, processor: EqualizerProcessor) -> AVAudioMix? {
        guard let tap = makeTap(processor) else { return nil }
        let parameters = AVMutableAudioMixInputParameters(track: track)
        parameters.audioTapProcessor = tap
        let mix = AVMutableAudioMix()
        mix.inputParameters = [parameters]
        return mix
    }

    /// The tap keeps the processor alive until it is finalized.
    private static func makeTap(_ processor: EqualizerProcessor) -> MTAudioProcessingTap? {
        let retainedProcessor = Unmanaged.passRetained(processor).toOpaque()
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: retainedProcessor,
            init: { _, clientInfo, storage in
                storage.pointee = clientInfo
            },
            finalize: { tap in
                Unmanaged<EqualizerProcessor>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release()
            },
            prepare: { tap, _, format in
                let format = format.pointee
                guard format.isFloat32 else { return }
                EqualizerTap.processor(of: tap).prepare(sampleRate: format.mSampleRate, channelCount: Int(format.mChannelsPerFrame))
            },
            unprepare: nil,
            process: { tap, frameCount, _, buffers, framesOut, flagsOut in
                guard MTAudioProcessingTapGetSourceAudio(tap, frameCount, buffers, flagsOut, nil, framesOut) == noErr else { return }
                EqualizerTap.processor(of: tap).process(UnsafeMutableAudioBufferListPointer(buffers), frameCount: Int(framesOut.pointee))
            }
        )

        var tap: MTAudioProcessingTap?
        let status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        guard status == noErr, let tap else {
            Unmanaged<EqualizerProcessor>.fromOpaque(retainedProcessor).release()
            return nil
        }
        return tap
    }

    private static func processor(of tap: MTAudioProcessingTap) -> EqualizerProcessor {
        Unmanaged<EqualizerProcessor>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    }
}

private nonisolated extension AudioStreamBasicDescription {
    var isFloat32: Bool {
        mFormatID == kAudioFormatLinearPCM && mFormatFlags & kAudioFormatFlagIsFloat != 0 && mBitsPerChannel == 32
    }
}
