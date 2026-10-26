package phanan.koel.app.audio

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.annotation.OptIn
import androidx.media3.common.ForwardingSimpleBasePlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.LibraryResult
import androidx.media3.session.SessionError
import androidx.media3.session.MediaController
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionToken
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.guava.future
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import phanan.koel.app.KoelApplication
import phanan.koel.app.MainActivity
import phanan.koel.shared.player.PlayerController

/**
 * Background playback with the media notification, lock screen and Bluetooth controls, and the
 * library Android Auto browses.
 */
class PlaybackService : MediaLibraryService() {
    private var session: MediaLibrarySession? = null
    private val scope = MainScope()

    @OptIn(UnstableApi::class)
    override fun onCreate() {
        super.onCreate()
        val app = (application as KoelApplication).app
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val tree = MediaTree(app, packageName)
        session = MediaLibrarySession.Builder(this, ControllerBackedPlayer(app.engine.player, app.core.player), LibraryCallback(tree))
            .setSessionActivity(openApp)
            .build()
        app.engine.onPlayerChanged = { player -> session?.player = ControllerBackedPlayer(player, app.core.player) }
        scope.launch {
            app.core.player.state.map { it.isRadioMode }.distinctUntilChanged().drop(1).collect {
                (session?.player as? ControllerBackedPlayer)?.refreshCommands()
            }
        }
        scope.launch {
            app.phase.drop(1).collect {
                tree.folderIds.forEach { folderId -> session?.notifyChildrenChanged(folderId, 0, null) }
            }
        }
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaLibrarySession? = session

    override fun onDestroy() {
        (application as KoelApplication).app.engine.onPlayerChanged = null
        session?.run {
            release()
            session = null
        }
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        /** Connecting keeps the service alive, and lets it go foreground while playing. */
        fun connect(context: Context): ListenableFuture<MediaController> =
            MediaController.Builder(context, SessionToken(context, ComponentName(context, PlaybackService::class.java))).buildAsync()

        /**
         * For controls outside the app, like the widget and the Quick Settings tile: playback they
         * start gets the media session, notification and foreground service that keep Android from
         * closing the app.
         */
        suspend fun control(context: Context, command: PlayerController.() -> Unit): Unit = withContext(Dispatchers.Main) {
            val app = (context.applicationContext as KoelApplication).app
            val player = app.core.player
            val connection = connect(context)
            try {
                connection.await()
                if (player.state.value.queue.isEmpty()) app.launchWithoutScreen()
                val wasPlaying = player.state.value.isPlaying
                player.command()
                if (!wasPlaying) withTimeoutOrNull(PLAYBACK_START_TIMEOUT_MS) { player.state.first { it.isPlaying } }
            } finally {
                MediaController.releaseFuture(connection)
            }
        }

        private const val PLAYBACK_START_TIMEOUT_MS = 5_000L
    }

    private inner class LibraryCallback(private val tree: MediaTree) : MediaLibrarySession.Callback {
        override fun onGetLibraryRoot(
            session: MediaLibrarySession,
            browser: MediaSession.ControllerInfo,
            params: LibraryParams?,
        ): ListenableFuture<LibraryResult<MediaItem>> = Futures.immediateFuture(LibraryResult.ofItem(tree.root, params))

        override fun onGetChildren(
            session: MediaLibrarySession,
            browser: MediaSession.ControllerInfo,
            parentId: String,
            page: Int,
            pageSize: Int,
            params: LibraryParams?,
        ): ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> = scope.future {
            runCatching {
                tree.children(parentId)?.let { LibraryResult.ofItemList(it, params) }
                    ?: LibraryResult.ofError(SessionError(SessionError.ERROR_SESSION_AUTHENTICATION_EXPIRED, "Log in on your phone to start listening."))
            }.getOrElse { LibraryResult.ofError(LibraryResult.RESULT_ERROR_IO) }
        }

        override fun onGetItem(
            session: MediaLibrarySession,
            browser: MediaSession.ControllerInfo,
            mediaId: String,
        ): ListenableFuture<LibraryResult<MediaItem>> =
            Futures.immediateFuture(LibraryResult.ofItem(tree.itemById(mediaId), null))

        /** Picking something in Android Auto hands it to the core, which plays it like a tap in the app. */
        override fun onSetMediaItems(
            mediaSession: MediaSession,
            controller: MediaSession.ControllerInfo,
            mediaItems: MutableList<MediaItem>,
            startIndex: Int,
            startPositionMs: Long,
        ): ListenableFuture<MediaSession.MediaItemsWithStartPosition> = scope.future {
            mediaItems.getOrNull(startIndex.coerceAtLeast(0))?.let { runCatching { tree.play(it.mediaId) } }
            MediaSession.MediaItemsWithStartPosition(mediaItems, startIndex, startPositionMs)
        }
    }
}

/**
 * ExoPlayer only ever holds the current item; the queue lives in the core. Commands from the
 * system go to the core's controller, so skipping and pausing work the same as in the app.
 */
@OptIn(UnstableApi::class)
private class ControllerBackedPlayer(player: Player, private val controller: PlayerController) :
    ForwardingSimpleBasePlayer(player) {

    override fun getState(): State {
        val state = super.getState()
        val commands = state.availableCommands.buildUpon()
        if (controller.state.value.isRadioMode) {
            commands.removeAll(*SKIP_COMMANDS)
        } else {
            commands.addAll(Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_PREVIOUS)
        }
        return state.buildUpon().setAvailableCommands(commands.build()).build()
    }

    /** Skipping comes and goes with the radio, which changes nothing ExoPlayer would report by itself. */
    fun refreshCommands() = invalidateState()

    override fun handleSetPlayWhenReady(playWhenReady: Boolean): ListenableFuture<*> {
        if (playWhenReady) controller.play() else controller.pause()
        return Futures.immediateVoidFuture()
    }

    override fun handleSeek(mediaItemIndex: Int, positionMs: Long, seekCommand: Int): ListenableFuture<*> {
        when (seekCommand) {
            Player.COMMAND_SEEK_TO_NEXT, Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM -> controller.skipToNext()
            Player.COMMAND_SEEK_TO_PREVIOUS, Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM -> controller.skipToPrevious()
            else -> controller.seek(positionMs / 1000.0)
        }
        return Futures.immediateVoidFuture()
    }

    /** The core already started playing what was picked, see `onSetMediaItems`. */
    override fun handleSetMediaItems(mediaItems: MutableList<MediaItem>, startIndex: Int, startPositionMs: Long): ListenableFuture<*> =
        Futures.immediateVoidFuture()

    override fun handlePrepare(): ListenableFuture<*> = Futures.immediateVoidFuture()

    override fun handleStop(): ListenableFuture<*> {
        controller.stop()
        return Futures.immediateVoidFuture()
    }

    private companion object {
        val SKIP_COMMANDS = intArrayOf(
            Player.COMMAND_SEEK_TO_NEXT,
            Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM,
            Player.COMMAND_SEEK_TO_PREVIOUS,
            Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM,
        )
    }
}
