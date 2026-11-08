package phanan.koel.app.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.theme.LocalBrandColor

/** Koel's segmented control, as on iOS: rounded corners, the selected segment in the cover's color. */
@Composable
fun SegmentedTabs(titles: List<String>, selectedIndex: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier) {
    val brandColor = LocalBrandColor.current
    Row(
        modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(9.dp))
            .padding(2.dp)
            .selectableGroup(),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        titles.forEachIndexed { index, title ->
            val isSelected = index == selectedIndex
            val background by animateColorAsState(if (isSelected) brandColor else Color.Transparent, label = "segment")
            Box(
                Modifier
                    .weight(1f)
                    .height(32.dp)
                    .background(background, RoundedCornerShape(7.dp))
                    .selectable(selected = isSelected, role = Role.Tab, onClick = { onSelect(index) }),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    title,
                    color = if (isSelected) Color.White else KoelColors.text,
                    fontSize = 15.sp,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                )
            }
        }
    }
}
