package phanan.koel.app.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import phanan.koel.app.ui.LocalAppModel
import phanan.koel.app.ui.theme.BrandMesh

/** Room below a screen's last item, so it doesn't sit against the navigation bar or the mini player. */
val ScreenBottomPadding = 32.dp

/**
 * A screen inside a tab: a large title that collapses as the content scrolls, with a back
 * button when the screen isn't the tab's first, over the brand mesh header.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScreenScaffold(
    title: String,
    modifier: Modifier = Modifier,
    isLargeTitle: Boolean = true,
    actions: @Composable RowScope.() -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    val app = LocalAppModel.current
    val navigator = app.navigator
    val canGoBack = !app.isOffline && navigator.stack(navigator.selectedTab).size > 1
    val scrollBehavior = if (isLargeTitle) {
        TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    } else {
        TopAppBarDefaults.pinnedScrollBehavior()
    }
    val navigationIcon: @Composable () -> Unit = {
        if (canGoBack) {
            IconButton(onClick = { navigator.pop() }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
        }
    }

    val barColors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent, scrolledContainerColor = BrandMesh.base)
    val barState = scrollBehavior.state
    Box(Modifier.fillMaxSize()) {
        BrandMeshHeaderBackground(scrolledDistance = { -barState.heightOffset - barState.contentOffset })

        Scaffold(
            modifier = modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
            contentWindowInsets = WindowInsets(0),
            containerColor = Color.Transparent,
            topBar = {
                if (isLargeTitle) {
                    LargeTopAppBar(
                        title = { Text(title, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                        navigationIcon = navigationIcon,
                        actions = actions,
                        scrollBehavior = scrollBehavior,
                        colors = barColors,
                    )
                } else {
                    TopAppBar(
                        title = { Text(title, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                        navigationIcon = navigationIcon,
                        actions = actions,
                        scrollBehavior = scrollBehavior,
                        colors = barColors,
                    )
                }
            },
            content = content,
        )
    }
}

/**
 * A [ScreenScaffold] whose content pulls to refresh [loading]: [placeholder] while there is
 * nothing to list yet, otherwise [content], which pads its top by the given app bar height and
 * its bottom by [ScreenBottomPadding].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RefreshableListScaffold(
    title: String,
    loading: Loading,
    isEmpty: Boolean,
    placeholder: @Composable BoxScope.(topPadding: Dp) -> Unit,
    isLargeTitle: Boolean = true,
    canRefresh: Boolean = true,
    actions: @Composable RowScope.() -> Unit = {},
    content: @Composable BoxScope.(topPadding: Dp) -> Unit,
) {
    ScreenScaffold(title = title, isLargeTitle = isLargeTitle, actions = actions) { padding ->
        val topPadding = padding.calculateTopPadding()
        val body: @Composable BoxScope.() -> Unit = {
            if (isEmpty) PullableFullHeight { placeholder(topPadding) } else content(topPadding)
        }
        if (canRefresh) {
            PullToRefreshBox(isRefreshing = loading.isPullRefreshing, onRefresh = loading::refresh, modifier = Modifier.fillMaxSize(), content = body)
        } else {
            Box(Modifier.fillMaxSize(), content = body)
        }
    }
}

/** Fills the screen's height and scrolls, so pull to refresh also works over a screen with nothing to list. */
@Composable
private fun PullableFullHeight(content: @Composable BoxScope.() -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val height = maxHeight
        Box(Modifier.verticalScroll(rememberScrollState())) {
            Box(Modifier.fillMaxWidth().height(height), content = content)
        }
    }
}
