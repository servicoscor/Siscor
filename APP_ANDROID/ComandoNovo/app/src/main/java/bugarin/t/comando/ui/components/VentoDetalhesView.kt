@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import bugarin.t.comando.data.EstacaoMeteorologica
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun VentoDetalhesView(
    estacoes: List<EstacaoMeteorologica>,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false),
        windowInsets = WindowInsets(0.dp) // Ocupa a tela toda
    ) {
        Column(
            modifier = Modifier
                .fillMaxHeight(0.9f) // Usa 90% da altura da tela
                .navigationBarsPadding()
        ) {
            // Header
            HeaderVento(estacoes = estacoes, onDismiss = onDismiss, localizationViewModel = localizationViewModel)

            // Conteúdo principal
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Rosa dos ventos animada
                estacoes.firstOrNull()?.let { estacaoPrincipal ->
                    item {
                        Card(
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                Text(
                                    text = estacaoPrincipal.nome ?: "Estação Principal",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                WindRose(
                                    direction = estacaoPrincipal.dirMed ?: "N",
                                    speed = (estacaoPrincipal.velMed ?: 0f) * 3.6f,
                                    modifier = Modifier.size(200.dp)
                                )
                            }
                        }
                    }
                }

                // Lista de outras estações
                items(estacoes.sortedByDescending { it.velMed ?: 0f }) { estacao ->
                    EstacaoVentoCard(
                        estacao = estacao,
                        localizationViewModel = localizationViewModel
                    )
                }
            }
        }
    }
}

@Composable
private fun HeaderVento(
    estacoes: List<EstacaoMeteorologica>,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val velocidades = remember(estacoes) { estacoes.mapNotNull { it.velMed } }
    val mediaVelocidade = velocidades.average() * 3.6
    val maxVelocidade = (velocidades.maxOrNull() ?: 0f) * 3.6

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                // ✅ TEMATIZAÇÃO: Usando cores do tema para o gradiente.
                Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary,
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.7f)
                    )
                )
            )
            .statusBarsPadding()
            .padding(20.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Default.Air, null, tint = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.size(28.dp))
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = localizationViewModel.getString("wind"),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.weight(1f)
            )
            IconButton(onClick = onDismiss) {
                Icon(Icons.Default.Close, localizationViewModel.getString("close"), tint = MaterialTheme.colorScheme.onPrimary)
            }
        }

        if (estacoes.isNotEmpty()) {
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                InfoCard("Média", "%.0f km/h".format(mediaVelocidade), getColorForWindSpeed(mediaVelocidade.toFloat()))
                InfoCard("Máxima", "%.0f km/h".format(maxVelocidade), getColorForWindSpeed(maxVelocidade.toFloat()))
            }
        }
    }
}


@Composable
private fun WindRose(direction: String, speed: Float, modifier: Modifier = Modifier) {
    val directionAngle = getAngleFromDirection(direction)
    val animatedRotation by animateFloatAsState(
        targetValue = directionAngle,
        animationSpec = tween(durationMillis = 1500, easing = EaseInOutCubic),
        label = "windRoseRotation"
    )
    val speedColor = getColorForWindSpeed(speed)

    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawWindRose(size.minDimension)
        }
        Icon(
            imageVector = Icons.Default.Navigation,
            contentDescription = null,
            modifier = Modifier
                .size(40.dp)
                .align(Alignment.TopCenter)
                .offset(y = (-10).dp) // Pequeno ajuste para a ponta da seta alinhar com o centro
                .rotate(animatedRotation),
            tint = speedColor
        )
        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surface, shadowElevation = 4.dp) {
            Column(
                modifier = Modifier.size(80.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "%.0f".format(speed),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = speedColor
                )
                Text("km/h", style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

private fun DrawScope.drawWindRose(size: Float) {
    val center = this.center
    val radius = size / 2 * 0.9f
    val strokeColor = Color.Gray.copy(alpha = 0.5f)

    listOf(0f, 45f, 90f, 135f, 180f, 225f, 270f, 315f).forEach { angle ->
        rotate(angle, center) {
            drawLine(strokeColor, start = center, end = Offset(center.x, center.y - radius), strokeWidth = 2f)
        }
    }
}

@Composable
private fun EstacaoVentoCard(estacao: EstacaoMeteorologica, localizationViewModel: LocalizationViewModel) {
    Card(elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(estacao.nome ?: localizationViewModel.getString("unknown"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(estacao.fonte ?: "", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Navigation, null, modifier = Modifier.size(20.dp).rotate(getAngleFromDirection(estacao.dirMed ?: "N")), tint = MaterialTheme.colorScheme.primary)
                    Text(estacao.dirMed ?: "N/A", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }
            }
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                val speedKmh = (estacao.velMed ?: 0f) * 3.6f
                MeteoInfo(Icons.Default.Air, "Velocidade", "%.1f".format(speedKmh), "km/h", getColorForWindSpeed(speedKmh))
                MeteoInfo(Icons.Default.Thermostat, "Temperatura", estacao.temMed?.let { "%.1f".format(it) } ?: "-", "°C")
                MeteoInfo(Icons.Default.WaterDrop, "Umidade", estacao.umdMed?.let { "%.0f".format(it) } ?: "-", "%")
            }
        }
    }
}

@Composable
private fun MeteoInfo(icon: ImageVector, label: String, value: String, unit: String, color: Color = MaterialTheme.colorScheme.onSurface) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, null, modifier = Modifier.size(20.dp), tint = MaterialTheme.colorScheme.primary)
        Spacer(modifier = Modifier.height(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = color)
        Text(unit, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun InfoCard(title: String, value: String, color: Color) {
    Card(
        modifier = Modifier.widthIn(min = 120.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White.copy(alpha = 0.15f)),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 8.dp, horizontal = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(title, style = MaterialTheme.typography.labelMedium, color = Color.White.copy(alpha = 0.8f))
            Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = color)
        }
    }
}

@Composable
private fun getColorForWindSpeed(kmh: Float): Color {
    // ✅ TEMATIZAÇÃO: Mapeia a velocidade para cores semânticas do tema.
    return when {
        kmh < 20f -> MaterialTheme.colorScheme.tertiary // Verde/Azul calmo
        kmh < 40f -> MaterialTheme.colorScheme.primary // Azul padrão
        kmh < 60f -> Color(0xFFFF9800) // Laranja para alerta (cor de warning comum)
        else -> MaterialTheme.colorScheme.error // Vermelho para perigo
    }
}

private fun getAngleFromDirection(direction: String): Float {
    return when (direction.uppercase()) {
        "N" -> 0f
        "NNE" -> 22.5f
        "NE" -> 45f
        "ENE" -> 67.5f
        "E" -> 90f
        "ESE" -> 112.5f
        "SE" -> 135f
        "SSE" -> 157.5f
        "S" -> 180f
        "SSW", "SSO" -> 202.5f
        "SW", "SO" -> 225f
        "WSW", "OSO" -> 247.5f
        "W", "O" -> 270f
        "WNW", "ONO" -> 292.5f
        "NW", "NO" -> 315f
        "NNW", "NNO" -> 337.5f
        else -> 0f
    }
}