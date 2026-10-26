package phanan.koel.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import phanan.koel.app.ui.theme.BrandMesh
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.KoelInputs

/** What kind of input a [FormField] is. Every kind hands back its value as a string. */
sealed interface FormFieldKind {
    data object Text : FormFieldKind

    /** A switch; its value is "true" or "false". */
    data object Toggle : FormFieldKind

    /** One of [options], given as value to label; its value is the chosen option's value. */
    class Picker(val options: List<Pair<String, String>>) : FormFieldKind
}

class FormField(
    val label: String,
    val initialValue: String = "",
    val isRequired: Boolean = false,
    val keyboardType: KeyboardType = KeyboardType.Text,
    val isSingleLine: Boolean = true,
    val kind: FormFieldKind = FormFieldKind.Text,
    val sanitize: (String) -> String = { it },
)

/**
 * A form in a bottom sheet over the brand backdrop, like the Flutter app's form sheets. It stays
 * open while [onSubmit] runs and shows its error inline; it closes once [onSubmit] succeeds.
 * [fields] may change while it is open, such as a picker showing up once its options load; what
 * was typed stays with each field by its label.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FormSheet(
    title: String,
    fields: List<FormField>,
    submitLabel: String = "Save",
    onDismiss: () -> Unit,
    onSubmit: suspend (List<String>) -> Unit,
) {
    val editedValues = remember { mutableStateMapOf<String, String>() }
    fun valueOf(field: FormField) = editedValues[field.label] ?: field.initialValue
    val scope = rememberCoroutineScope()
    var isSubmitting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val firstField = remember { FocusRequester() }
    val canSubmit = !isSubmitting && fields.all { !it.isRequired || valueOf(it).isNotBlank() }

    fun submit() {
        if (!canSubmit) return
        isSubmitting = true
        error = null
        scope.launch {
            runCatching { onSubmit(fields.map { valueOf(it).trim() }) }
                .onSuccess { onDismiss() }
                .onFailure { error = it.message?.takeIf { message -> message.isNotBlank() && message.length < 120 } ?: "Something went wrong. Please try again." }
            isSubmitting = false
        }
    }

    ModalBottomSheet(
        onDismissRequest = { if (!isSubmitting) onDismiss() },
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = BrandMesh.base,
        dragHandle = null,
    ) {
        Box {
            BrandMeshBackground(Modifier.matchParentSize())
            Column(
                Modifier
                    .navigationBarsPadding()
                    .imePadding()
                    .padding(start = 24.dp, end = 24.dp, top = 20.dp, bottom = 24.dp),
            ) {
                SheetDragHandle(Modifier.align(Alignment.CenterHorizontally))
                Spacer(Modifier.height(20.dp))
                Text(title, style = MaterialTheme.typography.headlineSmall.copy(fontSize = 24.sp, fontWeight = FontWeight.Bold))
                Spacer(Modifier.height(28.dp))
                Column(
                    Modifier.heightIn(max = 420.dp).verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    fields.forEachIndexed { index, field ->
                        val focus = if (index == 0) Modifier.focusRequester(firstField) else Modifier
                        when (val kind = field.kind) {
                            FormFieldKind.Text -> TextField(
                                value = valueOf(field),
                                onValueChange = { editedValues[field.label] = field.sanitize(it) },
                                label = { Text(field.label) },
                                singleLine = field.isSingleLine,
                                keyboardOptions = KeyboardOptions(keyboardType = field.keyboardType),
                                shape = KoelInputs.shape,
                                colors = KoelInputs.colors(),
                                modifier = Modifier.fillMaxWidth().then(focus),
                            )
                            FormFieldKind.Toggle -> ToggleRow(field.label, valueOf(field) == "true") { editedValues[field.label] = it.toString() }
                            is FormFieldKind.Picker -> PickerRow(field.label, kind.options, valueOf(field)) { editedValues[field.label] = it }
                        }
                    }
                }
                error?.let {
                    Spacer(Modifier.height(12.dp))
                    Text(it, color = KoelColors.destructiveSwipe, style = MaterialTheme.typography.bodyMedium)
                }
                Spacer(Modifier.height(32.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    TextButton(onClick = onDismiss, enabled = !isSubmitting, modifier = Modifier.weight(1f)) {
                        Text("Cancel", color = if (isSubmitting) KoelColors.hairline else Color.White.copy(alpha = 0.54f), fontSize = 16.sp)
                    }
                    Button(onClick = ::submit, enabled = canSubmit, shape = KoelInputs.shape, modifier = Modifier.weight(1f).height(48.dp)) {
                        if (isSubmitting) {
                            CircularProgressIndicator(Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
                        } else {
                            Text(submitLabel, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        if (fields.firstOrNull()?.kind == FormFieldKind.Text) runCatching { firstField.requestFocus() }
    }
}

@Composable
fun ToggleRow(label: String, isOn: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(KoelColors.inputFill, KoelInputs.shape)
            .clickable { onChange(!isOn) }
            .padding(horizontal = 18.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, modifier = Modifier.weight(1f))
        Switch(
            checked = isOn,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(checkedTrackColor = KoelColors.highlight, checkedThumbColor = Color.White),
        )
    }
}

/** Some of a picker's options, under an optional heading. */
class PickerSection(val title: String?, val options: List<Pair<String, String>>)

/** A labelled row that shows the chosen option and opens a menu of [options], given as value to label. */
@Composable
fun PickerRow(label: String, options: List<Pair<String, String>>, value: String, onChange: (String) -> Unit) =
    PickerRow(label, listOf(PickerSection(null, options)), value, onChange = onChange)

/** A picker whose menu groups its options in [sections]. Shows [placeholder] while [value] is none of them. */
@Composable
fun PickerRow(
    label: String,
    sections: List<PickerSection>,
    value: String,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    onChange: (String) -> Unit,
) {
    var isOpen by remember { mutableStateOf(false) }
    val options = sections.flatMap { it.options }
    Box(modifier) {
        Row(
            Modifier
                .fillMaxWidth()
                .background(KoelColors.inputFill, KoelInputs.shape)
                .clickable { isOpen = true }
                .padding(horizontal = 18.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(label, modifier = Modifier.weight(1f))
            Text(options.firstOrNull { it.first == value }?.second ?: placeholder, color = KoelColors.secondaryText)
        }
        DropdownMenu(expanded = isOpen, onDismissRequest = { isOpen = false }) {
            sections.forEach { section ->
                section.title?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.labelMedium,
                        color = KoelColors.secondaryText,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    )
                }
                section.options.forEach { (optionValue, optionLabel) ->
                    DropdownMenuItem(
                        text = { Text(optionLabel) },
                        trailingIcon = { if (optionValue == value) Icon(Icons.Default.Check, contentDescription = "Selected") },
                        onClick = {
                            isOpen = false
                            onChange(optionValue)
                        },
                    )
                }
            }
        }
    }
}

/**
 * Asks before something that can't be undone, like deleting a playlist, from the bottom of the
 * screen as iOS does: the title, the message, the red action and Cancel.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConfirmDialog(title: String, message: String? = null, confirmLabel: String, onDismiss: () -> Unit, onConfirm: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = KoelColors.menu) {
        Column(
            Modifier.navigationBarsPadding().padding(start = 24.dp, end = 24.dp, bottom = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            SheetTitle(title)
            message?.let {
                Spacer(Modifier.height(6.dp))
                Text(it, style = MaterialTheme.typography.bodyMedium, color = KoelColors.secondaryText)
            }
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = {
                    onDismiss()
                    onConfirm()
                },
                shape = KoelInputs.shape,
                colors = ButtonDefaults.buttonColors(containerColor = KoelColors.destructiveSwipe, contentColor = Color.White),
                modifier = Modifier.fillMaxWidth().height(48.dp),
            ) { Text(confirmLabel, fontWeight = FontWeight.SemiBold, fontSize = 16.sp) }
            Spacer(Modifier.height(8.dp))
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth().height(48.dp)) {
                Text("Cancel", color = KoelColors.text, fontSize = 16.sp)
            }
        }
    }
}

/**
 * One item in a menu. Destructive items are red; an item that [startsSection] gets a divider above
 * it, grouping items the way iOS menus do. An item that [opensFollowUp] replaces its action sheet
 * with another sheet or dialog, which closes the menu itself.
 */
class MenuAction(
    val label: String,
    val icon: ImageVector? = null,
    val isDestructive: Boolean = false,
    val isEnabled: Boolean = true,
    val startsSection: Boolean = false,
    val opensFollowUp: Boolean = false,
    val onClick: () -> Unit,
)

/** The items of a menu, with their icons and section dividers. */
@Composable
fun MenuItems(actions: List<MenuAction>, onPicked: () -> Unit) {
    actions.forEachIndexed { index, action ->
        if (action.startsSection && index > 0) HorizontalDivider(color = KoelColors.hairline)
        val color = if (action.isDestructive) KoelColors.destructiveSwipe else KoelColors.text
        DropdownMenuItem(
            text = { Text(action.label, color = color) },
            leadingIcon = action.icon?.let { icon -> { Icon(icon, contentDescription = null, tint = color) } },
            enabled = action.isEnabled,
            onClick = {
                onPicked()
                action.onClick()
            },
        )
    }
}

/** A button in an app bar that opens a menu: by default the "…" with the screen's less common actions. */
@Composable
fun OverflowMenu(actions: List<MenuAction>, icon: ImageVector = Icons.Default.MoreHoriz, label: String = "More") {
    if (actions.isEmpty()) return
    var isOpen by remember { mutableStateOf(false) }
    Box {
        IconButton(onClick = { isOpen = true }) { Icon(icon, contentDescription = label) }
        DropdownMenu(expanded = isOpen, onDismissRequest = { isOpen = false }) {
            MenuItems(actions) { isOpen = false }
        }
    }
}
