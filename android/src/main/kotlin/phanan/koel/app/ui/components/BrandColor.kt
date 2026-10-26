package phanan.koel.app.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.lerp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.collections.rememberCoverColor
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.LocalBrandColor

/** Follows what's playing and publishes its cover color as [LocalBrandColor], as the iOS app does. */
@Composable
fun ProvideNowPlayingBrandColor(content: @Composable () -> Unit) {
    val app = LocalAppModel.current
    val state by app.core.player.state.collectAsStateWithLifecycle()
    val coverColor by rememberCoverColor(state.radioStation?.logo ?: state.current?.artworkUrl)
    val brandColor = lerp(KoelColors.highlight, coverColor.copy(alpha = 1f), coverColor.alpha)
    CompositionLocalProvider(LocalBrandColor provides brandColor, content = content)
}
