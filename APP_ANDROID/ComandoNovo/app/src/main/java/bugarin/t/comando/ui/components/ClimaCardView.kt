package bugarin.t.comando.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import bugarin.t.comando.ui.theme.BaseCard
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel

// Data class para representar as condições climáticas
data class CondicaoClimatica(
    val calorValor: String,
    val calorTitulo: String,
    val chuvaValor: String,
    val chuvaTitulo: String,
    val ventoValor: String,
    val ventoTitulo: String,
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

    BaseCard(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
        gradient = cardGradient
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
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
                        // ✅ CORRIGIDO: Botão do calor usa onHeatLevelClick
                        InfoSegmentButton(
                            icon = Icons.Filled.Thermostat,
                            value = condicaoClimatica.calorValor,
                            title = condicaoClimatica.calorTitulo,
                            onClick = onHeatLevelClick, // ✅ USA A FUNÇÃO DE VALIDAÇÃO
                            modifier = Modifier.weight(1f)
                        )

                        // ✅ Botões de chuva e vento continuam normais
                        InfoSegmentButton(
                            icon = if (condicaoClimatica.isChovendo) Icons.Filled.WaterDrop else Icons.Filled.Umbrella,
                            value = condicaoClimatica.chuvaValor,
                            title = condicaoClimatica.chuvaTitulo,
                            onClick = { navController.navigate("chuva_detalhes") },
                            modifier = Modifier.weight(1f)
                        )

                        InfoSegmentButton(
                            icon = Icons.Filled.Air,
                            value = condicaoClimatica.ventoValor,
                            title = condicaoClimatica.ventoTitulo,
                            onClick = { navController.navigate("vento_detalhes") },
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
    modifier: Modifier = Modifier
) {
    // ✅ TEMATIZAÇÃO: Cores baseadas no tema.
    val containerColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.1f)
    val contentColor = MaterialTheme.colorScheme.onPrimary
    val titleColor = contentColor.copy(alpha = 0.7f)
    val borderColor = contentColor.copy(alpha = 0.2f)

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