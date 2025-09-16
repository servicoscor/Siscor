package bugarin.t.comando.ui.theme

import android.os.Build
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

// Cores principais do COR (Centro de Operações Rio)
val CORBlue = Color(0xFF1A80E5)
val CORBlueLight = Color(0xFF4D99E5)
val CORBlueDark = Color(0xFF0D47A1)

// Cores do tema claro
val Purple40 = Color(0xFF6650a4)
val PurpleGrey40 = Color(0xFF625b71)
val Pink40 = Color(0xFF7D5260)

// Cores do tema escuro
val Purple80 = Color(0xFFD0BCFF)
val PurpleGrey80 = Color(0xFFCCC2DC)
val Pink80 = Color(0xFFEFB8C8)

// Cores adicionais do app
val HeaderColor = CORBlue
val CardGradientStartColor = CORBlue
val CardGradientEndColor = CORBlueLight

// Cores para diferentes tipos de cards
val AlertRed = Color(0xFFD32F2F)
val AlertRedLight = Color(0xFFF44336)
val EventPurple = Color(0xFF7B1FA2)
val EventPurpleLight = Color(0xFFAB47BC)
val WeatherBlue = Color(0xFF1976D2)
val WeatherBlueLight = Color(0xFF42A5F5)

// Gradientes padrão
val cardGradient = Brush.verticalGradient(
    colors = listOf(
        CardGradientStartColor,
        CardGradientEndColor
    )
)

// Gradiente para cards de alerta
val alertCardGradient = Brush.verticalGradient(
    colors = listOf(AlertRed, AlertRedLight)
)

// Gradiente para cards de evento
val eventCardGradient = Brush.verticalGradient(
    colors = listOf(EventPurple, EventPurpleLight)
)

// Gradiente para cards de clima
val climaCardGradient = Brush.verticalGradient(
    colors = listOf(WeatherBlue, WeatherBlueLight)
)

// Borda padrão para cards
@Composable
fun cardBorder() = BorderStroke(
    width = 1.dp,
    color = Color.White.copy(alpha = 0.2f)
)

// Card base reutilizável
@Composable
fun BaseCard(
    modifier: Modifier = Modifier,
    gradient: Brush = cardGradient,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        border = cardBorder()
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(gradient)
        ) {
            Column(content = content)
        }
    }
}

// Esquemas de cores customizados
private val DarkColorScheme = darkColorScheme(
    primary = CORBlueLight,
    onPrimary = Color.White,
    primaryContainer = CORBlueDark,
    onPrimaryContainer = Color.White,
    secondary = Purple80,
    onSecondary = Color.Black,
    tertiary = Pink80,
    onTertiary = Color.Black,
    background = Color(0xFF121212),
    surface = Color(0xFF1E1E1E),
    onBackground = Color.White,
    onSurface = Color.White,
    error = Color(0xFFCF6679),
    onError = Color.Black
)

private val LightColorScheme = lightColorScheme(
    primary = CORBlue,
    onPrimary = Color.White,
    primaryContainer = CORBlueLight,
    onPrimaryContainer = Color.White,
    secondary = Purple40,
    onSecondary = Color.White,
    tertiary = Pink40,
    onTertiary = Color.White,
    background = Color(0xFFF5F5F5),
    surface = Color.White,
    onBackground = Color.Black,
    onSurface = Color.Black,
    error = Color(0xFFB00020),
    onError = Color.White
)

// Tema principal do app
@Composable
fun CORTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = false, // Desabilitado por padrão para manter as cores do COR
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

// Extensões úteis para Modifier
fun Modifier.glassEffect() = this
    .background(
        Color.White.copy(alpha = 0.1f),
        shape = RoundedCornerShape(12.dp)
    )
    .then(
        Modifier.background(
            Brush.verticalGradient(
                colors = listOf(
                    Color.White.copy(alpha = 0.1f),
                    Color.White.copy(alpha = 0.05f)
                )
            ),
            shape = RoundedCornerShape(12.dp)
        )
    )

// Cores por tipo de evento (baseado no iOS)
fun getEventTypeColor(tipo: String): Color {
    return when (tipo.lowercase()) {
        "esportivo" -> Color(0xFF4CAF50)
        "musical" -> Color(0xFF9C27B0)
        "cultural" -> Color(0xFFFF9800)
        "educacional" -> Color(0xFF2196F3)
        "gastronomico" -> Color(0xFFFF5722)
        else -> Color(0xFF607D8B)
    }
}

// Cores para níveis de estágio
fun getStageColor(stage: Int): Color {
    return when (stage) {
        1, 2 -> Color(0xFF4CAF50) // Verde
        3 -> Color(0xFFFFEB3B) // Amarelo
        4 -> Color(0xFFFF9800) // Laranja
        5 -> Color(0xFFF44336) // Vermelho
        else -> Color(0xFF9E9E9E) // Cinza
    }
}

// Cores para condições climáticas
fun getWeatherGradient(isNight: Boolean, isRaining: Boolean, condition: String): Brush {
    return when {
        isRaining && isNight -> Brush.verticalGradient(
            colors = listOf(Color(0xFF1A237E), Color(0xFF3949AB))
        )
        isRaining -> Brush.verticalGradient(
            colors = listOf(Color(0xFF64B5F6), Color(0xFF90CAF9))
        )
        isNight -> Brush.verticalGradient(
            colors = listOf(Color(0xFF0D47A1), Color(0xFF1976D2))
        )
        condition.contains("nublado", ignoreCase = true) -> Brush.verticalGradient(
            colors = listOf(Color(0xFF78909C), Color(0xFFB0BEC5))
        )
        else -> Brush.verticalGradient(
            colors = listOf(Color(0xFF81D4FA), Color(0xFFB3E5FC))
        )
    }
}