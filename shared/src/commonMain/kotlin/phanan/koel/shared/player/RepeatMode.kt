package phanan.koel.shared.player

enum class RepeatMode {
    NONE,
    ALL,
    ONE,
    ;

    fun next(): RepeatMode = when (this) {
        NONE -> ALL
        ALL -> ONE
        ONE -> NONE
    }
}
