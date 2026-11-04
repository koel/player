package phanan.koel.app.ui

import phanan.koel.app.ui.theme.KoelColors
import phanan.koel.app.ui.components.BrandMeshBackground
import phanan.koel.app.ui.components.LoadFailure
import phanan.koel.app.ui.components.GlassButton
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.TextButton
import androidx.compose.material3.Icon
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.Icons
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.Image
import androidx.compose.ui.res.painterResource
import phanan.koel.app.R
import androidx.compose.foundation.layout.Box
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import phanan.koel.app.AppModel
import phanan.koel.app.ui.auth.LoginScreen
import phanan.koel.app.ui.main.MainScreen

val LocalAppModel = staticCompositionLocalOf<AppModel> { error("No AppModel provided") }

@Composable
fun Root(app: AppModel) {
    val phase by app.phase.collectAsStateWithLifecycle()

    CompositionLocalProvider(LocalAppModel provides app) {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
            Crossfade(targetState = phase, label = "phase") { current ->
                when (current) {
                    AppModel.Phase.Launching -> {
                        LaunchedEffect(Unit) { app.launch() }
                        LaunchBackdrop { LaunchLogo() }
                    }
                    AppModel.Phase.NoConnection -> NoConnectionScreen()
                    AppModel.Phase.Login -> LoginScreen()
                    AppModel.Phase.Loading -> DataLoadingScreen()
                    AppModel.Phase.Main, AppModel.Phase.Offline -> MainScreen()
                }
            }
        }
    }
}

/** Shown when the app starts without a connection; it carries on by itself once one comes back. */
@Composable
private fun NoConnectionScreen() {
    val app = LocalAppModel.current

    LaunchBackdrop {
        StatusMessage(Icons.Default.WifiOff, "You are offline.", "Please connect to the internet and try again.")
        GlassButton("View downloaded songs", onClick = app::goOffline)
    }
}

@Composable
private fun DataLoadingScreen() {
    val app = LocalAppModel.current
    val hasDownloads = app.core.downloads.playables.collectAsStateWithLifecycle().value.isNotEmpty()
    var attempt by remember { mutableIntStateOf(0) }
    var hasFailed by remember { mutableStateOf(false) }
    var isTakingLong by remember { mutableStateOf(false) }

    LaunchedEffect(attempt) {
        hasFailed = false
        isTakingLong = false
        val slowNotice = launch {
            delay(6_000)
            isTakingLong = true
        }
        try {
            withTimeout(30_000) { app.loadData() }
        } catch (error: Exception) {
            hasFailed = true
        } finally {
            slowNotice.cancel()
        }
    }

    LaunchBackdrop {
        if (hasFailed) {
            StatusMessage(
                Icons.Default.CloudOff,
                LoadFailure.TITLE,
                LoadFailure.MESSAGE,
            )
            GlassButton(LoadFailure.RETRY, onClick = { attempt++ })
            TextButton(onClick = { app.logOut() }) {
                Text("Log Out", color = MaterialTheme.colorScheme.error)
            }
        } else {
            LargeSpinner()
            AnimatedVisibility(isTakingLong) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(24.dp)) {
                    Text("This is taking longer than usual…", color = KoelColors.secondaryText, textAlign = TextAlign.Center)
                    if (hasDownloads) GlassButton("View Downloads", onClick = app::goOffline)
                }
            }
        }
    }
}

/** The brand mesh with centered content, for the screens shown before the library is ready. */
@Composable
private fun LaunchLogo() {
    Image(
        painter = painterResource(R.drawable.logo),
        contentDescription = "Koel",
        modifier = Modifier.size(120.dp),
    )
}

@Composable
private fun LaunchBackdrop(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxSize()) {
        BrandMeshBackground()
        Column(
            modifier = Modifier.fillMaxSize().padding(40.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            content()
        }
    }
}

/** An icon, a title and a line of explanation, like iOS's ContentUnavailableView. */
@Composable
private fun StatusMessage(icon: ImageVector, title: String, description: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(icon, contentDescription = null, tint = KoelColors.secondaryText, modifier = Modifier.size(48.dp).padding(bottom = 4.dp))
        Text(title, style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold), textAlign = TextAlign.Center)
        Text(description, style = MaterialTheme.typography.bodyMedium, color = KoelColors.secondaryText, textAlign = TextAlign.Center)
    }
}

@Composable
private fun LargeSpinner() {
    CircularProgressIndicator(color = Color.White, strokeWidth = 3.dp, modifier = Modifier.size(40.dp))
}

@Composable
fun Centered(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        content()
    }
}
