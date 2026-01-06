package bugarin.t.comando.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import bugarin.t.comando.data.Sirene
import bugarin.t.comando.viewmodel.LocalizationViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SirenesStatusButton(
    sirenes: List<Sirene>,
    action: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val haptic = LocalHapticFeedback.current
    val currentLanguage by localizationViewModel.currentLanguage.collectAsState()

    val sirenesStatus = remember(sirenes, currentLanguage) {
        calculateSirenesStatus(sirenes, localizationViewModel)
    }

    // ✅ TEMATIZAÇÃO: Define a cor do conteúdo (texto e ícones) com base no tema.
    val contentColor = MaterialTheme.colorScheme.onPrimary

    Card(
        onClick = {
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            action()
        },
        interactionSource = interactionSource,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .scale(if (isPressed) 0.96f else 1f),
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
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.08f),
                            Color.White.copy(alpha = 0.04f)
                        )
                    ),
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Campaign,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = contentColor // Usa a cor do tema
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = sirenesStatus.title,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Bold,
                        shadow = Shadow(Color.Black.copy(alpha = 0.3f), Offset(0f, 2f), 2f)
                    ),
                    color = contentColor, // Usa a cor do tema
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = sirenesStatus.subtitle,
                    style = MaterialTheme.typography.bodySmall.copy(
                        shadow = Shadow(Color.Black.copy(alpha = 0.3f), Offset(0f, 2f), 2f)
                    ),
                    color = contentColor.copy(alpha = 0.9f), // Usa a cor do tema
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Reflexo no topo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                    .background(
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                contentColor.copy(alpha = 0.1f), // Usa a cor do tema
                                Color.Transparent
                            )
                        )
                    )
            )
        }
    }
}

private data class SirenesStatusInfo(
    val title: String,
    val subtitle: String
)

private fun calculateSirenesStatus(
    sirenes: List<Sirene>,
    localizationViewModel: LocalizationViewModel
): SirenesStatusInfo {
    val activeSirensCount = sirenes.count { sirene ->
        sirene.status?.lowercase()?.let { status ->
            status.contains("acionada") || status.contains("mobilizada")
        } ?: false
    }

    return if (activeSirensCount > 0) {
        SirenesStatusInfo(
            title = localizationViewModel.getString("sirens_active"),
            subtitle = localizationViewModel.getString("sirens_active_count", activeSirensCount)
        )
    } else {
        SirenesStatusInfo(
            title = localizationViewModel.getString("no_sirens"),
            subtitle = localizationViewModel.getString("no_sirens_active")
        )
    }
}
