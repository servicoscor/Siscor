package bugarin.t.comando.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import bugarin.t.comando.R

@Composable
fun BrandedLoadingView(
    message: String? = null,
    modifier: Modifier = Modifier,
    // ✅ TEMATIZAÇÃO: Permite que a cor do loading seja controlada pelo tema.
    contentColor: Color = MaterialTheme.colorScheme.onSurface
) {
    // ✅ BOAS PRÁTICAS: Adicionadas labels descritivas para depuração de animações.
    val infiniteTransition = rememberInfiniteTransition(label = "LoadingPulseTransition")
    val outerScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.5f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ), label = "OuterPulseScale"
    )
    val outerAlpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ), label = "OuterPulseAlpha"
    )
    val innerScale by infiniteTransition.animateFloat(
        initialValue = 0.9f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, delayMillis = 200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ), label = "InnerPulseScale"
    )
    val innerAlpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, delayMillis = 200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ), label = "InnerPulseAlpha"
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(150.dp)
        ) {
            // Círculo externo pulsante
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .scale(outerScale)
                    .alpha(outerAlpha)
                    .border(
                        width = 2.dp,
                        color = contentColor.copy(alpha = 0.3f), // Usa a cor do tema
                        shape = CircleShape
                    )
            )

            // Círculo interno pulsante
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .scale(innerScale)
                    .alpha(innerAlpha)
                    .border(
                        width = 2.dp,
                        color = contentColor.copy(alpha = 0.5f), // Usa a cor do tema
                        shape = CircleShape
                    )
            )

            // Logo no centro
            Image(
                painter = painterResource(id = R.drawable.loading),
                contentDescription = "Loading",
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .size(80.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .shadow(elevation = 5.dp, shape = RoundedCornerShape(18.dp))
            )
        }

        message?.let { msg ->
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = msg,
                style = MaterialTheme.typography.bodyLarge,
                color = contentColor.copy(alpha = 0.9f), // Usa a cor do tema
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }
    }
}