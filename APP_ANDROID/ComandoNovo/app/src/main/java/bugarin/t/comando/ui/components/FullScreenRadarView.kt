@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun FullScreenRadarView(
    onNavigateBack: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    var webViewState by remember { mutableStateOf<WebViewState>(WebViewState.Loading) }
    var reloadTrigger by remember { mutableStateOf(0) }
    val radarUrl = "https://aplicativo.cocr.com.br/radar_emb_app"
    val context = LocalContext.current

    BackHandler {
        kotlin.runCatching {
            onNavigateBack()
        }.onFailure { e ->
            android.util.Log.e("FullScreenRadarView", "Error in back handler: ${e.message}")
        }
    }

    // Cleanup quando componente é removido
    DisposableEffect(Unit) {
        onDispose {
            android.util.Log.d("FullScreenRadarView", "Cleaning up fullscreen radar view")
            kotlin.runCatching {
                System.gc()
            }.onFailure { e ->
                android.util.Log.e("FullScreenRadarView", "Error during cleanup: ${e.message}")
            }
        }
    }

    Scaffold(
        topBar = {
            HeaderSectionRadar(
                onRefresh = {
                    kotlin.runCatching {
                        webViewState = WebViewState.Loading
                        reloadTrigger++
                    }.onFailure { e ->
                        android.util.Log.e("FullScreenRadarView", "Error refreshing: ${e.message}")
                    }
                },
                onShareClick = {
                    kotlin.runCatching {
                        if (context is android.app.Activity && !context.isFinishing && !context.isDestroyed) {
                            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, radarUrl)
                            }
                            val chooser = Intent.createChooser(shareIntent, localizationViewModel.getString("share_radar"))

                            if (chooser.resolveActivity(context.packageManager) != null) {
                                context.startActivity(chooser)
                            } else {
                                android.util.Log.w("FullScreenRadarView", "No app available to handle share intent")
                            }
                        } else {
                            android.util.Log.w("FullScreenRadarView", "Context is not valid for sharing")
                        }
                    }.onFailure { e ->
                        android.util.Log.e("FullScreenRadarView", "Error sharing radar: ${e.message}")
                    }
                },
                onOpenInBrowser = {
                    kotlin.runCatching {
                        if (context is android.app.Activity && !context.isFinishing && !context.isDestroyed) {
                            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(radarUrl))

                            if (browserIntent.resolveActivity(context.packageManager) != null) {
                                context.startActivity(browserIntent)
                            } else {
                                android.util.Log.w("FullScreenRadarView", "No browser available")
                            }
                        } else {
                            android.util.Log.w("FullScreenRadarView", "Context is not valid for opening browser")
                        }
                    }.onFailure { e ->
                        android.util.Log.e("FullScreenRadarView", "Error opening browser: ${e.message}")
                    }
                },
                onDismiss = {
                    kotlin.runCatching {
                        onNavigateBack()
                    }.onFailure { e ->
                        android.util.Log.e("FullScreenRadarView", "Error dismissing: ${e.message}")
                    }
                },
                localizationViewModel = localizationViewModel
            )
        },
        containerColor = MaterialTheme.colorScheme.surface
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.surface),
            contentAlignment = Alignment.Center
        ) {
            ControlledWebView(
                modifier = Modifier.fillMaxSize(),
                sessionId = "radar_fullscreen_${System.currentTimeMillis()}",
                url = radarUrl,
                reloadTrigger = reloadTrigger,
                onStateChange = { newState ->
                    kotlin.runCatching {
                        webViewState = newState
                    }.onFailure { e ->
                        android.util.Log.e("FullScreenRadarView", "Error updating state: ${e.message}")
                    }
                }
            )

            // Criar variável local para evitar smart cast issues
            val currentState = webViewState
            when (currentState) {
                is WebViewState.Loading -> LoadingOverlay(localizationViewModel)
                is WebViewState.Error -> ErrorOverlay(
                    errorMessage = currentState.message,
                    onRetry = {
                        kotlin.runCatching {
                            webViewState = WebViewState.Loading
                            reloadTrigger++
                        }.onFailure { e ->
                            android.util.Log.e("FullScreenRadarView", "Error retrying: ${e.message}")
                        }
                    },
                    localizationViewModel = localizationViewModel
                )
                is WebViewState.Success -> { /* Não mostra overlay no sucesso */ }
                else -> {}
            }
        }
    }
}

@Composable
private fun HeaderSectionRadar(
    onRefresh: () -> Unit,
    onShareClick: () -> Unit,
    onOpenInBrowser: () -> Unit,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    TopAppBar(
        title = {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(Icons.Default.SatelliteAlt, null, tint = MaterialTheme.colorScheme.primary)
                Text(localizationViewModel.getString("weather_radar"), fontWeight = FontWeight.Bold)
            }
        },
        actions = {
            var showMenu by remember { mutableStateOf(false) }

            IconButton(onClick = {
                kotlin.runCatching {
                    onRefresh()
                }.onFailure { e ->
                    android.util.Log.e("HeaderSectionRadar", "Error refreshing: ${e.message}")
                }
            }) {
                Icon(Icons.Default.Refresh, localizationViewModel.getString("refresh"))
            }

            Box {
                IconButton(onClick = {
                    kotlin.runCatching {
                        showMenu = true
                    }.onFailure { e ->
                        android.util.Log.e("HeaderSectionRadar", "Error showing menu: ${e.message}")
                    }
                }) {
                    Icon(Icons.Default.MoreVert, localizationViewModel.getString("more_options"))
                }

                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false }
                ) {
                    DropdownMenuItem(
                        text = { Text(localizationViewModel.getString("share_radar")) },
                        leadingIcon = { Icon(Icons.Default.Share, null) },
                        onClick = {
                            kotlin.runCatching {
                                showMenu = false
                                onShareClick()
                            }.onFailure { e ->
                                android.util.Log.e("HeaderSectionRadar", "Error in share menu: ${e.message}")
                            }
                        }
                    )
                    DropdownMenuItem(
                        text = { Text(localizationViewModel.getString("open_in_browser")) },
                        leadingIcon = { Icon(Icons.Default.OpenInNew, null) },
                        onClick = {
                            kotlin.runCatching {
                                showMenu = false
                                onOpenInBrowser()
                            }.onFailure { e ->
                                android.util.Log.e("HeaderSectionRadar", "Error in browser menu: ${e.message}")
                            }
                        }
                    )
                }
            }

            IconButton(onClick = {
                kotlin.runCatching {
                    onDismiss()
                }.onFailure { e ->
                    android.util.Log.e("HeaderSectionRadar", "Error dismissing: ${e.message}")
                }
            }) {
                Icon(Icons.Default.Close, localizationViewModel.getString("close"))
            }
        }
    )
}

@Composable
private fun LoadingOverlay(localizationViewModel: LocalizationViewModel) {
    Box(
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            CircularProgressIndicator()
            Text(localizationViewModel.getString("loading_radar"))
        }
    }
}

@Composable
private fun ErrorOverlay(
    errorMessage: String? = null,
    onRetry: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Box(
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(Icons.Default.CloudOff, null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(localizationViewModel.getString("radar_load_error"), style = MaterialTheme.typography.headlineSmall)
            Text(
                errorMessage ?: localizationViewModel.getString("check_connection"),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Button(onClick = {
                kotlin.runCatching {
                    onRetry()
                }.onFailure { e ->
                    android.util.Log.e("ErrorOverlay", "Error retrying: ${e.message}")
                }
            }) {
                Icon(Icons.Default.Refresh, null, Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                Text(localizationViewModel.getString("try_again"))
            }
        }
    }
}