package bugarin.t.comando.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import bugarin.t.comando.data.InformeTempo
import bugarin.t.comando.ui.theme.BaseCard
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel

// ✅ PERFORMANCE: Data class otimizada para exibição
private data class WeatherDisplayInfo(
    val icon: ImageVector,
    val color: Color,
    val typeText: String,
    val isSevere: Boolean
)

@Composable
fun InformesTempoView(
    informes: List<InformeTempo>,
    isLoading: Boolean,
    localizationViewModel: LocalizationViewModel
) {
    BaseCard(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        gradient = cardGradient
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header otimizado
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Cloud,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
                Text(
                    text = localizationViewModel.getString("weather_reports"),
                    style = MaterialTheme.typography.headlineSmall.copy(
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                )

                if (informes.isNotEmpty()) {
                    Spacer(modifier = Modifier.weight(1f))
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = Color.White.copy(alpha = 0.2f)
                    ) {
                        Text(
                            text = informes.size.toString(),
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelLarge.copy(
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Content com altura fixa otimizada
            when {
                isLoading -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }
                informes.isEmpty() -> {
                    EmptyStateView(
                        icon = Icons.Default.CloudOff,
                        message = localizationViewModel.getString("no_weather_reports"),
                        contentColor = Color.White
                    )
                }
                else -> {
                    // ✅ PERFORMANCE: LazyRow com altura fixa para evitar layout loops
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 4.dp),
                        modifier = Modifier.height(200.dp) // ✅ ALTURA FIXA
                    ) {
                        items(informes, key = { it.id }) { informe ->
                            OptimizedInformeTempoCard(
                                informe = informe,
                                localizationViewModel = localizationViewModel
                            )
                        }
                    }
                }
            }
        }
    }
}

// ✅ PERFORMANCE: Card otimizado com dimensões fixas
@Composable
private fun OptimizedInformeTempoCard(
    informe: InformeTempo,
    localizationViewModel: LocalizationViewModel
) {
    // ✅ PERFORMANCE: Cached display info
    val displayInfo = remember(informe.id, informe.texto) {
        calculateWeatherDisplayInfo(informe, localizationViewModel)
    }

    Card(
        modifier = Modifier
            .width(280.dp) // ✅ LARGURA FIXA
            .fillMaxHeight(), // Usar altura disponível do LazyRow
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.White.copy(alpha = 0.1f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Borda colorida no topo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .background(color = displayInfo.color)
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
                    .weight(1f),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Header com ícone e tipo
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = displayInfo.icon,
                        contentDescription = null,
                        tint = displayInfo.color,
                        modifier = Modifier.size(20.dp)
                    )

                    Text(
                        text = displayInfo.typeText,
                        style = MaterialTheme.typography.labelLarge.copy(
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.9f)
                        )
                    )

                    Spacer(modifier = Modifier.weight(1f))

                    if (displayInfo.isSevere) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = Color(0xFFFF5252),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }

                // ✅ PERFORMANCE: Texto com limite de linhas otimizado
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                ) {
                    Text(
                        text = informe.texto?.replace("jumpline", "\n") ?: "",
                        style = MaterialTheme.typography.bodyMedium.copy(
                            lineHeight = 18.sp
                        ),
                        color = Color.White.copy(alpha = 0.85f),
                        overflow = TextOverflow.Ellipsis,
                        maxLines = 8 // ✅ LIMITE RAZOÁVEL em vez de 10000
                    )
                }
            }
        }
    }
}

// ✅ PERFORMANCE: Função otimizada para calcular info de exibição
private fun calculateWeatherDisplayInfo(
    informe: InformeTempo,
    localization: LocalizationViewModel
): WeatherDisplayInfo {
    val texto = informe.texto?.lowercase() ?: ""

    val isSevere = texto.contains("forte") ||
            texto.contains("intensa") ||
            texto.contains("tempestade") ||
            texto.contains("temporal") ||
            texto.contains("alerta") ||
            texto.contains("perigo")

    return when {
        texto.contains("tempestade") || texto.contains("temporal") -> WeatherDisplayInfo(
            icon = Icons.Default.Thunderstorm,
            color = Color(0xFFFF5252),
            typeText = localization.getString("storm"),
            isSevere = true
        )
        texto.contains("chuva forte") -> WeatherDisplayInfo(
            icon = Icons.Default.Umbrella,
            color = Color(0xFFFF9800),
            typeText = localization.getString("rain"),
            isSevere = true
        )
        texto.contains("chuva") || texto.contains("precipitação") -> WeatherDisplayInfo(
            icon = Icons.Default.Umbrella,
            color = Color(0xFF2196F3),
            typeText = localization.getString("rain"),
            isSevere = isSevere
        )
        texto.contains("vento forte") -> WeatherDisplayInfo(
            icon = Icons.Default.Air,
            color = Color(0xFF9C27B0),
            typeText = localization.getString("windy"),
            isSevere = true
        )
        texto.contains("vento") -> WeatherDisplayInfo(
            icon = Icons.Default.Air,
            color = Color(0xFF42A5F5),
            typeText = localization.getString("windy"),
            isSevere = isSevere
        )
        texto.contains("sol") || texto.contains("ensolarado") -> WeatherDisplayInfo(
            icon = Icons.Default.WbSunny,
            color = Color(0xFFFFEB3B),
            typeText = localization.getString("sunny"),
            isSevere = false
        )
        texto.contains("neblina") || texto.contains("nevoeiro") -> WeatherDisplayInfo(
            icon = Icons.Default.CloudQueue,
            color = Color(0xFF607D8B),
            typeText = localization.getString("foggy"),
            isSevere = isSevere
        )
        texto.contains("nublado") || texto.contains("nuvem") -> WeatherDisplayInfo(
            icon = Icons.Default.Cloud,
            color = Color(0xFF78909C),
            typeText = localization.getString("cloudy"),
            isSevere = isSevere
        )
        else -> WeatherDisplayInfo(
            icon = Icons.Default.CloudQueue,
            color = Color(0xFF42A5F5),
            typeText = localization.getString("weather_update"),
            isSevere = isSevere
        )
    }
}