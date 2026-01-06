package bugarin.t.comando.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.OpenInFull
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SatelliteAlt
import androidx.compose.material.icons.filled.ZoomOutMap
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import bugarin.t.comando.viewmodel.LocalizationViewModel

/**
 * ✅ ARQUITETURA: O Card do Radar foi simplificado para ser um "placeholder" leve.
 * Ele não contém mais um WebView, o que torna a rolagem na tela principal
 * extremamente performática. O WebView real viverá apenas na tela cheia.
 */
/**
 * ✅ ELEGANTE: Card do Radar com WebView integrado de forma otimizada.
 * Mostra o radar diretamente no card da tela principal com opção de expandir.
 * Performance otimizada para não impactar a rolagem da tela principal.
 */
/**
 * ✅ ELEGANTE: Card do Radar com WebView integrado de forma otimizada.
 * Mostra o radar diretamente no card da tela principal com opção de expandir.
 * Performance otimizada para não impactar a rolagem da tela principal.
 */
@Composable
fun RadarCardView(
    onExpand: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    var webViewState by remember { mutableStateOf<WebViewState>(WebViewState.Loading) }
    var reloadTrigger by remember { mutableStateOf(0) }
    val contentColor = MaterialTheme.colorScheme.onPrimary
    val radarUrl = "https://aplicativo.cocr.com.br/radar_emb_app"

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        border = BorderStroke(
            width = 1.5.dp,
            brush = Brush.verticalGradient(
                colors = listOf(
                    Color.White.copy(alpha = 0.4f),
                    Color.White.copy(alpha = 0.1f)
                )
            )
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.08f),
                            Color.White.copy(alpha = 0.04f)
                        )
                    )
                )
                .padding(16.dp)
        ) {
            // Header do Card
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.SatelliteAlt,
                        contentDescription = null,
                        tint = contentColor,
                        modifier = Modifier.size(24.dp)
                    )
                    Text(
                        text = localizationViewModel.getString("weather_radar"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = contentColor
                    )
                }

                // Botões de ação
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    // Botão de reload
                    IconButton(
                        onClick = {
                            webViewState = WebViewState.Loading
                            reloadTrigger++
                        },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = localizationViewModel.getString("refresh"),
                            tint = contentColor,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    // Botão de expandir
                    IconButton(
                        onClick = onExpand,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.OpenInFull,
                            contentDescription = localizationViewModel.getString("expand_radar"),
                            tint = contentColor,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Container do Radar com WebView
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(320.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.Black.copy(alpha = 0.3f))
                    .clickable { onExpand() } // Permite tocar no radar para expandir
            ) {
                // WebView do radar
                ControlledWebView(
                    modifier = Modifier.fillMaxSize(),
                    sessionId = "radar_card",
                    url = radarUrl,
                    reloadTrigger = reloadTrigger,
                    onStateChange = { newState -> webViewState = newState }
                )

                // Overlay de loading
                when (webViewState) {
                    WebViewState.Loading -> {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(Color.Black.copy(alpha = 0.7f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                CircularProgressIndicator(
                                    color = contentColor,
                                    modifier = Modifier.size(32.dp)
                                )
                                Text(
                                    text = localizationViewModel.getString("loading_radar"),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = contentColor
                                )
                            }
                        }
                    }

                    is WebViewState.Error -> {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(Color.Black.copy(alpha = 0.8f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.CloudOff,
                                    contentDescription = null,
                                    tint = contentColor.copy(alpha = 0.7f),
                                    modifier = Modifier.size(40.dp)
                                )
                                Text(
                                    text = localizationViewModel.getString("radar_load_error"),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = contentColor.copy(alpha = 0.9f)
                                )
                                Button(
                                    onClick = {
                                        webViewState = WebViewState.Loading
                                        reloadTrigger++
                                    },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = contentColor.copy(alpha = 0.2f)
                                    )
                                ) {
                                    Text(
                                        text = localizationViewModel.getString("try_again"),
                                        color = contentColor,
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                }
                            }
                        }
                    }

                    is WebViewState.Success -> {
                        // Indicador sutil de que pode ser expandido
                        Box(
                            modifier = Modifier
                                .align(Alignment.BottomEnd)
                                .padding(8.dp)
                        ) {
                            Surface(
                                shape = CircleShape,
                                color = Color.Black.copy(alpha = 0.5f),
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.ZoomOutMap,
                                    contentDescription = null,
                                    tint = contentColor,
                                    modifier = Modifier
                                        .size(16.dp)
                                        .padding(6.dp)
                                )
                            }
                        }
                    }

                    else -> {
                        // Estado padrão/fallback - não mostra overlay
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Legenda e status
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = localizationViewModel.getString("real_time_weather_monitoring"),
                    style = MaterialTheme.typography.bodySmall,
                    color = contentColor.copy(alpha = 0.7f)
                )

                // Indicador de status
                when (webViewState) {
                    is WebViewState.Success -> {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(6.dp)
                                    .background(Color.Green, CircleShape)
                            )
                            Text(
                                text = "Online",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.Green
                            )
                        }
                    }
                    is WebViewState.Error -> {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(6.dp)
                                    .background(Color.Red, CircleShape)
                            )
                            Text(
                                text = "Offline",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.Red
                            )
                        }
                    }
                    else -> {
                        // Não mostra status para outros estados
                    }
                }
            }
        }
    }
}

// ❌ REMOVIDO: O AnimatedWebViewOverlay e a lógica complexa de ciclo de vida
// não são mais necessários neste componente. Essa lógica deve ser movida para
// a sua tela 'FullScreenRadarView', que conterá o 'ControlledWebView' real.
