package bugarin.t.comando.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Construction
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Traffic
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import bugarin.t.comando.data.InformeTransito
import bugarin.t.comando.ui.theme.BaseCard
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel

private data class TrafficDisplayInfo(
    val borderColor: Color,
    val icon: ImageVector,
    val iconTint: Color,
    val typeText: String
)

@Composable
fun InformesTransitoCardView(
    informes: List<InformeTransito>,
    isLoading: Boolean,
    localizationViewModel: LocalizationViewModel
) {
    val contentColor = MaterialTheme.colorScheme.onPrimary

    BaseCard(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        gradient = cardGradient
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(Icons.Default.Traffic, null, tint = contentColor, modifier = Modifier.size(24.dp))
                Text(
                    text = localizationViewModel.getString("traffic_reports"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = contentColor
                )

                if (informes.isNotEmpty()) {
                    Spacer(modifier = Modifier.weight(1f))
                    Surface(shape = RoundedCornerShape(12.dp), color = contentColor.copy(alpha = 0.2f)) {
                        Text(
                            text = informes.size.toString(),
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold,
                            color = contentColor
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            when {
                isLoading -> Box(Modifier.fillMaxWidth().height(120.dp), Alignment.Center) { CircularProgressIndicator(color = contentColor) }
                informes.isEmpty() -> EmptyStateView(icon = Icons.Default.CheckCircle, message = localizationViewModel.getString("no_traffic_reports"), contentColor = contentColor)
                else -> {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp)
                    ) {
                        items(informes, key = { it.hashCode() }) { informe ->
                            InformeTransitoCard(informe, localizationViewModel)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InformeTransitoCard(informe: InformeTransito, localizationViewModel: LocalizationViewModel) {
    val displayInfo = rememberTrafficDisplayInfo(informe, localizationViewModel)

    Card(
        modifier = Modifier.width(280.dp).height(IntrinsicSize.Min), // Garante altura consistente na linha
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.1f))
    ) {
        Column {
            Box(modifier = Modifier.fillMaxWidth().height(4.dp).background(color = displayInfo.borderColor))
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(displayInfo.icon, null, tint = displayInfo.iconTint, modifier = Modifier.size(20.dp))
                    Text(
                        text = displayInfo.typeText,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White // ← Texto branco
                    )
                }
                Text(
                    text = informe.texto?.replace("jumpline", "\n")?.replace(";", "\n").orEmpty(),
                    style = MaterialTheme.typography.bodyMedium.copy(lineHeight = 18.sp),
                    color = Color.White // ← Texto branco
                )
            }
        }
    }
}

@Composable
private fun rememberTrafficDisplayInfo(informe: InformeTransito, localizationViewModel: LocalizationViewModel): TrafficDisplayInfo {
    // ✅ TEMATIZAÇÃO: As cores agora são baseadas no tema do Material Design.
    val errorColor = MaterialTheme.colorScheme.error
    val warningColor = Color(0xFFFF9800) // Laranja para Obras
    val infoColor = MaterialTheme.colorScheme.primary
    val closureColor = Color(0xFFFFEB3B) // Amarelo para Interdição

    return remember(informe) {
        val texto = informe.texto?.lowercase().orEmpty()
        when {
            texto.contains("acidente") -> TrafficDisplayInfo(
                borderColor = errorColor,
                icon = Icons.Default.Warning,
                iconTint = errorColor,
                typeText = localizationViewModel.getString("accident")
            )
            texto.contains("obras") -> TrafficDisplayInfo(
                borderColor = warningColor,
                icon = Icons.Default.Construction,
                iconTint = warningColor,
                typeText = localizationViewModel.getString("construction")
            )
            texto.contains("interdição") -> TrafficDisplayInfo(
                borderColor = closureColor,
                icon = Icons.Default.Block,
                iconTint = closureColor,
                typeText = localizationViewModel.getString("closure")
            )
            else -> TrafficDisplayInfo(
                borderColor = infoColor,
                icon = Icons.Default.Info,
                iconTint = infoColor,
                typeText = localizationViewModel.getString("info")
            )
        }
    }
}