package bugarin.t.comando.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import bugarin.t.comando.BuildConfig // ✅ NOVO: Import para a versão do app
import bugarin.t.comando.R
import bugarin.t.comando.ui.components.BrandedLoadingView
import bugarin.t.comando.viewmodel.ErrorType
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(
    isLoading: Boolean = true,
    hasError: Boolean = false,
    errorMessage: String? = null,
    errorType: ErrorType? = null,
    isOffline: Boolean = false,
    isRetrying: Boolean = false,
    retryCount: Int = 0,
    loadingProgress: Float = 0f,
    loadingMessage: String = "",
    onRetry: () -> Unit = {}
) {
    // Animation states
    var imageOpacity by remember { mutableStateOf(0f) }
    var contentOpacity by remember { mutableStateOf(0f) }

    // Animate on appear
    LaunchedEffect(Unit) {
        animate(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = tween(durationMillis = 800, easing = FastOutSlowInEasing)
        ) { value, _ -> imageOpacity = value }

        delay(300)
        animate(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = tween(durationMillis = 800, easing = FastOutSlowInEasing)
        ) { value, _ -> contentOpacity = value }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0D1B26)), // Dark blue background
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(40.dp),
            modifier = Modifier.padding(horizontal = 32.dp)
        ) {
            // Logo
            Image(
                painter = painterResource(id = R.drawable.logocordeitado),
                contentDescription = "Logo Centro de Operações Rio",
                modifier = Modifier
                    .width(250.dp)
                    .height(90.dp)
                    .alpha(imageOpacity),
                contentScale = ContentScale.Fit
            )

            // Content area
            Box(
                modifier = Modifier
                    .alpha(contentOpacity)
                    .heightIn(min = 200.dp),
                contentAlignment = Alignment.Center
            ) {
                when {
                    hasError -> {
                        // Error state
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.1f)),
                            border = CardDefaults.outlinedCardBorder()
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(16.dp),
                                modifier = Modifier.padding(24.dp)
                            ) {
                                val errorIcon = when (errorType) {
                                    ErrorType.NO_INTERNET -> Icons.Default.WifiOff
                                    ErrorType.TIMEOUT -> Icons.Default.TimerOff
                                    ErrorType.NO_DATA -> Icons.Default.CloudOff
                                    ErrorType.SERVER_ERROR -> Icons.Default.Dns
                                    else -> Icons.Default.Warning
                                }
                                Icon(
                                    imageVector = errorIcon,
                                    contentDescription = null,
                                    modifier = Modifier.size(48.dp),
                                    tint = MaterialTheme.colorScheme.error
                                )
                                Text(
                                    text = when (errorType) {
                                        ErrorType.NO_INTERNET -> "Sem conexão"
                                        ErrorType.TIMEOUT -> "Conexão lenta"
                                        ErrorType.NO_DATA -> "Sem dados disponíveis"
                                        ErrorType.SERVER_ERROR -> "Erro no servidor"
                                        else -> "Erro ao carregar dados"
                                    },
                                    style = MaterialTheme.typography.titleMedium,
                                    color = Color.White
                                )
                                Text(
                                    text = errorMessage ?: "Verifique sua conexão com a internet",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color.White.copy(alpha = 0.7f),
                                    textAlign = TextAlign.Center
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Button(
                                    onClick = onRetry,
                                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                                ) {
                                    Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Tentar novamente")
                                }
                            }
                        }
                    }

                    isOffline && !isLoading -> {
                        // Offline mode with cached data
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.CloudOff,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = Color(0xFFFF9800) // Orange
                            )
                            Text(
                                text = "Modo Offline",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White
                            )
                            Text(
                                text = "Usando dados salvos localmente",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.White.copy(alpha = 0.7f),
                                textAlign = TextAlign.Center
                            )
                        }
                    }

                    isLoading || isRetrying -> {
                        // Loading state
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(24.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            BrandedLoadingView()
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(12.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                // ✅ ATUALIZADO: A lógica de "Tentativa X/3" foi removida.
                                // A UI agora apenas exibe a mensagem que o ViewModel fornece.
                                Text(
                                    text = loadingMessage.ifEmpty { "Carregando..." },
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = Color.White.copy(alpha = 0.8f),
                                    textAlign = TextAlign.Center
                                )
                                Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 40.dp)) {
                                    LinearProgressIndicator(
                                        progress = loadingProgress,
                                        modifier = Modifier.fillMaxWidth().height(4.dp),
                                        color = MaterialTheme.colorScheme.primary,
                                        trackColor = Color.White.copy(alpha = 0.1f)
                                    )
                                }
                            }
                        }
                    }

                    else -> {
                        // Success state - dados carregados
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = Color(0xFF4CAF50) // Green
                            )
                            Text(
                                text = "Tudo pronto!",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White
                            )
                        }
                    }
                }
            }
        }

        // Footer com informações
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (!hasError) {
                Text(
                    text = "Centro de Operações Rio",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 14.sp
                )
            }
            // ✅ ATUALIZADO: A versão agora é lida do BuildConfig.
            Text(
                text = "v${BuildConfig.VERSION_NAME}",
                color = Color.White.copy(alpha = 0.3f),
                fontSize = 12.sp
            )
        }
    }
}