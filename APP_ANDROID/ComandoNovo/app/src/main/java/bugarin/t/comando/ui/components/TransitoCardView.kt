package bugarin.t.comando.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Traffic
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
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
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransitoCardView(
    action: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    var isPressed by remember { mutableStateOf(false) }
    val haptic = LocalHapticFeedback.current
    val scope = rememberCoroutineScope()

    // ✅ TEMATIZAÇÃO: As cores agora são baseadas no `onPrimary` do tema,
    // que é a cor correta para textos/ícones sobre um fundo de cor primária.
    val contentColor = MaterialTheme.colorScheme.onPrimary

    Card(
        onClick = {
            isPressed = true
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            scope.launch {
                action()
                delay(150)
                isPressed = false
            }
        },
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .scale(if (isPressed) 0.96f else 1f)
            .graphicsLayer { rotationX = if (isPressed) 2f else 0f },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isPressed) 4.dp else 8.dp)
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Gradiente de fundo
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = cardGradient, // Assumindo que este gradiente vem do seu tema
                        shape = RoundedCornerShape(16.dp)
                    )
            )

            // Borda sutil
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .border(
                        width = 1.dp,
                        color = contentColor.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(16.dp)
                    )
            )

            // Conteúdo
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Traffic,
                    contentDescription = null,
                    modifier = Modifier
                        .size(48.dp)
                        .shadow(elevation = 2.dp, shape = CircleShape),
                    tint = contentColor
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = localizationViewModel.getString("traffic"),
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Bold,
                        shadow = Shadow(Color.Black.copy(alpha = 0.3f), Offset(0f, 2f), 2f)
                    ),
                    color = contentColor,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = localizationViewModel.getString("traffic_conditions"),
                    style = MaterialTheme.typography.bodySmall.copy(
                        shadow = Shadow(Color.Black.copy(alpha = 0.3f), Offset(0f, 2f), 2f)
                    ),
                    color = contentColor.copy(alpha = 0.9f),
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Reflexo no topo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp)
                    .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                    .background(
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                contentColor.copy(alpha = 0.1f),
                                Color.Transparent
                            )
                        )
                    )
            )
        }
    }
}