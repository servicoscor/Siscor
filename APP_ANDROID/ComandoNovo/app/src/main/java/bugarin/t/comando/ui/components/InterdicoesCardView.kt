package bugarin.t.comando.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InterdicoesCardView(
    action: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ✅ REATORADO: Usando interactionSource para um controle de estado de "pressionado" mais robusto.
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val haptic = LocalHapticFeedback.current

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
            .scale(if (isPressed) 0.96f else 1f)
            .graphicsLayer { rotationX = if (isPressed) 2f else 0f },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isPressed) 4.dp else 8.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(brush = cardGradient, shape = RoundedCornerShape(16.dp))
                .border(
                    width = 1.dp,
                    color = contentColor.copy(alpha = 0.15f), // Usa a cor do tema
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            // Conteúdo do botão
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Block,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = contentColor // Usa a cor do tema
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = localizationViewModel.getString("interdictions"),
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Bold,
                        shadow = Shadow(Color.Black.copy(alpha = 0.3f), Offset(0f, 2f), 2f)
                    ),
                    color = contentColor, // Usa a cor do tema
                    textAlign = TextAlign.Center,
                    maxLines = 1
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = localizationViewModel.getString("blocked_roads"),
                    style = MaterialTheme.typography.bodySmall.copy(
                        shadow = Shadow(Color.Black.copy(alpha = 0.3f), Offset(0f, 2f), 2f)
                    ),
                    color = contentColor.copy(alpha = 0.9f), // Usa a cor do tema
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Efeito de reflexo no topo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp)
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