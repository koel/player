package phanan.koel.app.ui.collections

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.ContentUnavailable
import phanan.koel.app.ui.components.LoadingSpinner
import phanan.koel.app.ui.components.SheetTitle
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Artist

/** The artist's biography, opened from Info in the artist's menu, as on iOS. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ArtistInfoSheet(artist: Artist, onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val biography by produceState<String?>(null, artist.id) {
        value = runCatching { app.core.mediaInfo.fetchForArtist(artist.id).biography }.getOrDefault("").plainText
    }

    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Color.Black) {
        Column(Modifier.navigationBarsPadding().heightIn(min = LocalConfiguration.current.screenHeightDp.dp * 0.45f)) {
            Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                SheetTitle(artist.name, Modifier.align(Alignment.Center).padding(horizontal = 72.dp))
                Row(Modifier.align(Alignment.CenterEnd)) {
                    TextButton(onClick = onDismiss) { Text("Done", color = KoelColors.highlight, fontWeight = FontWeight.SemiBold) }
                }
            }
            val text = biography
            when {
                text == null -> LoadingSpinner(Modifier.fillMaxWidth().padding(48.dp))
                text.isBlank() -> ContentUnavailable("No artist information available.", Icons.Outlined.Info)
                else -> SelectionContainer {
                    Text(
                        text,
                        style = MaterialTheme.typography.bodyLarge.copy(fontSize = 17.sp, lineHeight = 24.sp),
                        modifier = Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
                    )
                }
            }
        }
    }
}
