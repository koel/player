package phanan.koel.shared.player

import phanan.koel.shared.models.Playable
import phanan.koel.shared.models.RadioStation

data class PlaybackState(
    val queue: List<Playable> = emptyList(),
    /** -1 when the current playable is not (or no longer) in the queue. */
    val currentIndex: Int = -1,
    val current: Playable? = null,
    val isPlaying: Boolean = false,
    val isBuffering: Boolean = false,
    val hasFailed: Boolean = false,
    val repeatMode: RepeatMode = RepeatMode.NONE,
    val volume: Double = 0.7,
    val radioStation: RadioStation? = null,
    val radioStreamTitle: String? = null,
) {
    val isRadioMode: Boolean get() = radioStation != null
}
