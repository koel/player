package phanan.koel.app.ui.player

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.components.ToggleRow
import phanan.koel.app.ui.components.ConfirmDialog
import phanan.koel.app.ui.components.FormField
import phanan.koel.app.ui.components.FormSheet
import phanan.koel.app.ui.components.KoelSlider
import phanan.koel.app.ui.components.PickerRow
import phanan.koel.app.ui.components.PickerSection
import phanan.koel.app.ui.components.SectionContentGap
import phanan.koel.app.ui.components.SectionSpacing
import phanan.koel.app.ui.components.SectionTitle
import phanan.koel.app.ui.components.SheetTitle
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.models.Equalizer
import phanan.koel.shared.models.EqualizerPreset
import phanan.koel.shared.stores.PlaybackSettingsStore
import kotlin.math.roundToInt

/** How the Now Playing sheet and the profile menu name the Playback sheet. */
object PlaybackSettingsEntry {
    const val LABEL = "Playback settings"
    val icon: ImageVector = Icons.Default.Tune
}

/** The equalizer and crossfade, like Koel web's. Every drag is heard right away. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlaybackSettingsSheet(onDismiss: () -> Unit) {
    val app = LocalAppModel.current
    val settings = app.core.playbackSettings
    val equalizer by settings.equalizer.collectAsStateWithLifecycle()
    val customPresets by settings.customPresets.collectAsStateWithLifecycle()
    val canSavePresets by settings.canSavePresets.collectAsStateWithLifecycle()
    val crossfadeDuration by settings.crossfadeDuration.collectAsStateWithLifecycle()
    val normalizeVolume by settings.normalizeVolume.collectAsStateWithLifecycle()
    val serverInfo by app.core.session.serverInfo.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var isSavingPreset by rememberSaveable { mutableStateOf(false) }
    var isConfirmingRemoval by rememberSaveable { mutableStateOf(false) }
    val presets = Equalizer.builtInPresets + customPresets
    val matchingPreset = Equalizer.presetMatching(equalizer, customPresets)
    val selectedCustomPreset = customPresets.firstOrNull { it.id == matchingPreset?.id }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = Color.Black,
    ) {
        Column(Modifier.navigationBarsPadding().verticalScroll(rememberScrollState()).padding(bottom = 24.dp)) {
            SheetTitle("Playback")
            Spacer(Modifier.height(SectionContentGap))
            SectionTitle("Equalizer")
            Column(
                Modifier.padding(horizontal = 16.dp, vertical = SectionContentGap),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    PickerRow(
                        "Preset",
                        PlaybackSettingsFormat.presetSections(customPresets),
                        matchingPreset?.id.orEmpty(),
                        modifier = Modifier.weight(1f),
                        placeholder = PlaybackSettingsFormat.CUSTOM_PRESET,
                    ) { id -> presets.firstOrNull { it.id == id }?.let(settings::setEqualizer) }
                    if (matchingPreset == null && canSavePresets) GhostButton("Save as…") { isSavingPreset = true }
                    if (selectedCustomPreset != null) GhostButton("Remove") { isConfirmingRemoval = true }
                }
                EqualizerPanel(equalizer, settings::setEqualizer)
            }
            SectionTitle("Crossfade", Modifier.padding(top = SectionSpacing - SectionContentGap))
            Row(Modifier.padding(horizontal = 16.dp, vertical = SectionContentGap)) {
                SliderRow("Duration", PlaybackSettingsFormat.crossfade(crossfadeDuration)) {
                    KoelSlider(
                        value = crossfadeDuration.toFloat(),
                        range = 0f..PlaybackSettingsStore.MAX_CROSSFADE_SECONDS.toFloat(),
                        onValueChange = { settings.setCrossfadeDuration(it.roundToInt()) },
                        label = "Crossfade",
                        steps = PlaybackSettingsStore.MAX_CROSSFADE_SECONDS - 1,
                        modifier = Modifier.fillMaxWidth().height(SliderHeight),
                    )
                }
            }
            if (serverInfo?.koelPlus == true) {
                SectionTitle("Volume", Modifier.padding(top = SectionSpacing - SectionContentGap))
                Box(Modifier.padding(horizontal = 16.dp, vertical = SectionContentGap)) {
                    ToggleRow(NORMALIZE_VOLUME_LABEL, normalizeVolume, settings::setNormalizeVolume)
                }
            }
        }
    }

    if (isSavingPreset) {
        FormSheet(
            title = "Save as Preset",
            fields = listOf(FormField("Name", isRequired = true)),
            onDismiss = { isSavingPreset = false },
        ) { values -> settings.savePreset(values.first()) }
    }

    if (isConfirmingRemoval) {
        selectedCustomPreset?.let { preset ->
            ConfirmDialog(
                title = "Remove preset?",
                message = "Remove “${preset.name}”?",
                confirmLabel = "Remove",
                onDismiss = { isConfirmingRemoval = false },
            ) { scope.launch { runCatching { settings.removePreset(preset) }.onFailure { app.messages.showError() } } }
        }
    }
}

/** Koel web's ghost button: just the label. */
@Composable
private fun GhostButton(label: String, onClick: () -> Unit) {
    TextButton(onClick = onClick, colors = ButtonDefaults.textButtonColors(contentColor = KoelColors.text)) { Text(label) }
}

@Composable
private fun SliderRow(label: String, value: String, slider: @Composable () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(label, modifier = Modifier.width(SliderLabelWidth))
        Row(Modifier.weight(1f)) { slider() }
        Text(value, color = KoelColors.secondaryText, textAlign = TextAlign.End, modifier = Modifier.width(SliderValueWidth))
    }
}

/** The Playback sheet's wording and the steps its sliders snap to. */
object PlaybackSettingsFormat {
    const val CUSTOM_PRESET = "Custom"

    /** The built-in presets, then any saved ones, grouped under headings only when there are saved ones. */
    fun presetSections(saved: List<EqualizerPreset>): List<PickerSection> {
        fun options(presets: List<EqualizerPreset>) = presets.mapNotNull { preset -> preset.id?.let { it to preset.name.orEmpty() } }
        return if (saved.isEmpty()) {
            listOf(PickerSection(null, options(Equalizer.builtInPresets)))
        } else {
            listOf(PickerSection("Built-in", options(Equalizer.builtInPresets)), PickerSection("Custom", options(saved)))
        }
    }

    fun snapped(decibels: Float): Double =
        ((decibels * 10).roundToInt() / 10.0).coerceIn(-Equalizer.MAX_DECIBELS, Equalizer.MAX_DECIBELS)

    fun crossfade(seconds: Int): String = if (seconds == 0) "Off" else "$seconds s"
}

private val SliderHeight = 34.dp
private val SliderLabelWidth = 72.dp
private val SliderValueWidth = 64.dp

const val NORMALIZE_VOLUME_LABEL = "Play songs at about the same volume"
