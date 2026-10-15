import AVFoundation

enum AudioSession {
    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
    }

    static func activate() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
