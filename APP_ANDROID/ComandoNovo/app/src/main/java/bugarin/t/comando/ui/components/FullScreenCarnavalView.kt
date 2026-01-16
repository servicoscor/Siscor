@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun FullScreenCarnavalView(
    onNavigateBack: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    var webViewState by remember { mutableStateOf<WebViewState>(WebViewState.Loading) }
    var reloadTrigger by remember { mutableStateOf(0) }
    val carnavalUrl = "https://carnaval2026.cor.rio/"

    BackHandler { onNavigateBack() }

    DisposableEffect(Unit) {
        onDispose {
            kotlin.runCatching { System.gc() }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Icon(Icons.Default.Celebration, null, tint = MaterialTheme.colorScheme.primary)
                        Text(
                            text = localizationViewModel.getString("carnival_2026_title"),
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {
                        webViewState = WebViewState.Loading
                        reloadTrigger++
                    }) {
                        Icon(Icons.Default.Refresh, localizationViewModel.getString("refresh"))
                    }
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.Close, localizationViewModel.getString("close"))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.surface
    ) { paddingValues: PaddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.surface),
            contentAlignment = Alignment.Center
        ) {
            ControlledWebView(
                modifier = Modifier.fillMaxSize(),
                sessionId = "carnaval_fullscreen_${System.currentTimeMillis()}",
                url = carnavalUrl,
                reloadTrigger = reloadTrigger,
                onStateChange = { webViewState = it },
                allowedHosts = setOf("carnaval2026.cor.rio")
            )

            when (val state = webViewState) {
                is WebViewState.Loading -> CarnavalLoadingOverlay(localizationViewModel)
                is WebViewState.Error -> CarnavalErrorOverlay(
                    errorMessage = state.message,
                    onRetry = {
                        webViewState = WebViewState.Loading
                        reloadTrigger++
                    },
                    localizationViewModel = localizationViewModel
                )
                else -> {}
            }
        }
    }
}

@Composable
private fun CarnavalLoadingOverlay(localizationViewModel: LocalizationViewModel) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            CircularProgressIndicator()
            Text(localizationViewModel.getString("loading"))
        }
    }
}

@Composable
private fun CarnavalErrorOverlay(
    errorMessage: String?,
    onRetry: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.surface),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.padding(24.dp)
        ) {
            Text(
                text = localizationViewModel.getString("error_loading_data"),
                style = MaterialTheme.typography.titleMedium
            )
            if (!errorMessage.isNullOrBlank()) {
                Text(
                    text = errorMessage,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.size(4.dp))
            Button(onClick = onRetry) {
                Icon(Icons.Default.Refresh, null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.size(8.dp))
                Text(localizationViewModel.getString("try_again"))
            }
        }
    }
}
