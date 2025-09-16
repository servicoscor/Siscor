@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.content.pm.ActivityInfo
import android.util.Log
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import bugarin.t.comando.ui.components.ControlledWebView
import bugarin.t.comando.ui.components.WebViewState
import bugarin.t.comando.viewmodel.CORViewModel
import bugarin.t.comando.viewmodel.LocalizationViewModel
import kotlinx.coroutines.delay

// Constante para timeout configurável
private const val CAMERA_LOADING_TIMEOUT_MS = 10000L

@Composable
fun CameraDetailScreen(
    cameraId: String,
    navController: NavController,
    cameraViewModel: CORViewModel,
    localizationViewModel: LocalizationViewModel,
    onSetOrientation: (Int) -> Unit // Callback obrigatório (removido nullable)
) {
    val uiState by cameraViewModel.uiState.collectAsStateWithLifecycle()
    val camera = remember(cameraId, uiState.cameras) {
        uiState.cameras.find { it.apiId == cameraId }
    }

    // Força a orientação para paisagem ao entrar na tela
    LaunchedEffect(Unit) {
        Log.d("CameraRotation", "Definindo orientação para paisagem...")
        onSetOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE)
        Log.d("CameraRotation", "Orientação definida com sucesso")
    }

    var webViewState by remember { mutableStateOf<WebViewState>(WebViewState.Loading) }
    var reloadTrigger by remember { mutableStateOf(0) }

    val streamUrl = camera?.apiId?.let { "https://aplicativo.cocr.com.br/camera/$it" }

    val navigateBack: () -> Unit = {
        onSetOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)
        navController.popBackStack()
    }

    BackHandler { navigateBack() }

    // Timeout configurável para o carregamento
    LaunchedEffect(reloadTrigger) {
        if (streamUrl != null) {
            delay(CAMERA_LOADING_TIMEOUT_MS)
            if (webViewState is WebViewState.Loading) {
                Log.w("CameraDetailScreen", "Loading timeout reached!")
                webViewState = WebViewState.Error("Timeout de conexão")
            }
        }
    }

    // Usando cores do MaterialTheme para consistência
    val backgroundColor = MaterialTheme.colorScheme.surface
    val contentColor = MaterialTheme.colorScheme.onSurface

    Scaffold(
        containerColor = backgroundColor,
        topBar = {
            CameraTopBar(
                cameraName = camera?.nome ?: localizationViewModel.getString("camera"),
                onNavigateBack = navigateBack,
                onRefresh = {
                    webViewState = WebViewState.Loading
                    reloadTrigger++
                },
                localizationViewModel = localizationViewModel
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(backgroundColor),
            contentAlignment = Alignment.Center
        ) {
            when {
                camera == null -> {
                    ErrorContent(
                        title = localizationViewModel.getString("error"),
                        message = localizationViewModel.getString("camera_not_found"),
                        onNavigateBack = navigateBack,
                        localizationViewModel = localizationViewModel
                    )
                }
                streamUrl != null -> {
                    ControlledWebView(
                        modifier = Modifier.fillMaxSize(),
                        url = streamUrl,
                        sessionId = "camera_$cameraId",
                        reloadTrigger = reloadTrigger,
                        onStateChange = { newState ->
                            // Não sobrescreve um erro de timeout
                            if (webViewState !is WebViewState.Error) {
                                webViewState = newState
                            }
                        }
                    )

                    // Overlay baseado no estado
                    when (val state = webViewState) {

                        is WebViewState.Success -> {
                            // Sucesso - não mostra overlay
                        }
                        else -> {}
                    }
                }
                else -> {
                    ErrorContent(
                        title = localizationViewModel.getString("error"),
                        message = localizationViewModel.getString("camera_id_not_available"),
                        onNavigateBack = navigateBack,
                        localizationViewModel = localizationViewModel
                    )
                }
            }
        }
    }

    // Limpa a orientação ao sair da tela
    DisposableEffect(Unit) {
        onDispose {
            onSetOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)
        }
    }
}

@Composable
private fun CameraTopBar(
    cameraName: String,
    onNavigateBack: () -> Unit,
    onRefresh: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    TopAppBar(
        title = {
            Text(
                text = cameraName,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        },
        navigationIcon = {
            IconButton(onClick = onNavigateBack) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = localizationViewModel.getString("back"),
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        },
        actions = {
            IconButton(onClick = onRefresh) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = localizationViewModel.getString("refresh"),
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.8f)
        )
    )
}



@Composable
private fun ErrorContent(
    title: String,
    message: String,
    onNavigateBack: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.padding(24.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Error,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.error,
            modifier = Modifier.size(48.dp)
        )
        Text(
            text = title,
            color = MaterialTheme.colorScheme.onSurface,
            style = MaterialTheme.typography.titleMedium
        )
        Text(
            text = message,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
            style = MaterialTheme.typography.bodySmall,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Button(
            onClick = onNavigateBack,
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Text(localizationViewModel.getString("back"))
        }
    }
}