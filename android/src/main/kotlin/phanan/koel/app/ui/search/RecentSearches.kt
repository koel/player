package phanan.koel.app.ui.search

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import phanan.koel.app.ui.components.SectionClearButton
import phanan.koel.app.ui.components.SectionContentGap
import phanan.koel.app.ui.components.SectionTitle
import phanan.koel.app.ui.components.SwipeAction
import phanan.koel.app.ui.components.SwipeActions
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.shared.stores.SearchStore

/** What Search shows before anything is typed: the latest searches to run again. */
@Composable
fun RecentSearches(store: SearchStore, run: (String) -> Unit) {
    val searches by store.recentSearches.collectAsStateWithLifecycle()

    if (searches.isEmpty()) return

    Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(SectionContentGap)) {
        SectionTitle("Recently Searched") { SectionClearButton(store::clearRecentSearches) }
        Column {
            searches.forEach { keywords ->
                RecentSearchRow(keywords, run = { run(keywords) }, remove = { store.forgetSearch(keywords) })
            }
        }
    }
}

@Composable
private fun RecentSearchRow(keywords: String, run: () -> Unit, remove: () -> Unit) {
    Column {
        SwipeActions(trailing = listOf(SwipeAction.destructive("Remove", Icons.Default.RemoveCircleOutline, remove))) {
            Row(
                Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(onClick = run).padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Default.History, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(18.dp))
                Text(keywords, style = MaterialTheme.typography.bodyLarge.copy(fontSize = 17.sp), modifier = Modifier.weight(1f))
            }
        }
        HorizontalDivider(Modifier.padding(start = 16.dp), color = KoelColors.hairline)
    }
}
