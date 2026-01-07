package bugarin.t.comando.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import bugarin.t.comando.viewmodel.LocalizationViewModel

// Data class para representar as condições climáticas
data class CondicaoClimatica(
    val calorValor: String,
    val calorTitulo: String,
    val estagioValor: String,
    val estagioTitulo: String,
    val estagioNumero: Int,
    val chuvaValor: String,
    val chuvaTitulo: String,
    val isChovendo: Boolean = false
)

@Composable
fun ClimaCardView(
    // ✅ ARQUITETURA: Recebe o objeto já processado e o estado de 'isLoading'
    condicaoClimatica: CondicaoClimatica?,
    isLoading: Boolean,
    localizationViewModel: LocalizationViewModel,
    navController: NavController,
    onHeatLevelClick: () -> Unit = {} // ✅ NOVO
) {
    val contentColor = MaterialTheme.colorScheme.onPrimary

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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(Icons.Filled.WbSunny, null, modifier = Modifier.size(24.dp), tint = contentColor)
                Text(
                    text = localizationViewModel.getString("weather_conditions"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = contentColor
                )
            }

            when {
                isLoading -> Box(Modifier.fillMaxWidth().height(80.dp), Alignment.Center) { CircularProgressIndicator(color = contentColor) }
                condicaoClimatica != null -> {
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        // Card 1: Calor
                        InfoSegmentButton(
                            icon = Icons.Filled.Thermostat,
                            value = condicaoClimatica.calorValor,
                            title = condicaoClimatica.calorTitulo,
                            onClick = onHeatLevelClick,
                            modifier = Modifier.weight(1f)
                        )

                        // Card 2: Estágio (NOVO - substituiu Vento)
                        InfoSegmentButton(
                            icon = Icons.Filled.Warning,
                            value = condicaoClimatica.estagioValor,
                            title = condicaoClimatica.estagioTitulo,
                            backgroundColor = getColorForStage(condicaoClimatica.estagioNumero),
                            onClick = { /* Navegar para detalhes do estágio se necessário */ },
                            modifier = Modifier.weight(1f)
                        )

                        // Card 3: Chuva
                        InfoSegmentButton(
                            icon = if (condicaoClimatica.isChovendo) Icons.Filled.WaterDrop else Icons.Filled.Umbrella,
                            value = condicaoClimatica.chuvaValor,
                            title = condicaoClimatica.chuvaTitulo,
                            onClick = { navController.navigate("chuva_detalhes") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                else -> EmptyStateView(icon = Icons.Default.CloudOff, message = localizationViewModel.getString("weather_data_unavailable"), contentColor = contentColor)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun InfoSegmentButton(
    icon: ImageVector,
    value: String,
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    backgroundColor: Color? = null
) {
    // ✅ TEMATIZAÇÃO: Cores baseadas no tema ou cor customizada para estágios
    val containerColor = backgroundColor?.copy(alpha = 0.15f) ?: MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.1f)
    val contentColor = backgroundColor ?: MaterialTheme.colorScheme.onPrimary
    val titleColor = contentColor.copy(alpha = 0.9f)
    val borderColor = contentColor.copy(alpha = 0.3f)

    Card(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = containerColor),
        border = BorderStroke(width = 1.dp, color = borderColor)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 8.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(icon, null, modifier = Modifier.size(28.dp), tint = contentColor)
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = title.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = titleColor,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = contentColor,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 1
                )
            }
        }
    }
}
