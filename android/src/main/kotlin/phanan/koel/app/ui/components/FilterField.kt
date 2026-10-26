package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.unit.dp
import phanan.koel.app.ui.theme.KoelColors

/** Material's search bar above a list, filtering it as the user types. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterField(text: String, onChange: (String) -> Unit, prompt: String = "Filter") {
    val focusManager = LocalFocusManager.current

    SearchBar(
        inputField = {
            SearchBarDefaults.InputField(
                query = text,
                onQueryChange = onChange,
                onSearch = { focusManager.clearFocus() },
                expanded = false,
                onExpandedChange = {},
                placeholder = { Text(prompt, color = KoelColors.faintText) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = KoelColors.secondaryText) },
                trailingIcon = if (text.isEmpty()) {
                    null
                } else {
                    {
                        IconButton(onClick = { onChange("") }) {
                            Icon(Icons.Default.Cancel, contentDescription = "Clear", tint = KoelColors.faintText)
                        }
                    }
                },
            )
        },
        expanded = false,
        onExpandedChange = {},
        colors = SearchBarDefaults.colors(containerColor = KoelColors.pill),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
    ) {}
}
