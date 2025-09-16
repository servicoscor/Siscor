package bugarin.t.comando.ui.theme

import androidx.compose.ui.graphics.Color

// Cores principais do Centro de Operações Rio
val CORPrimaryBlue = Color(0xFF1A80E5)
val CORSecondaryBlue = Color(0xFF4D99E5)
val CORDarkBlue = Color(0xFF0D47A1)

// Cores do Rio de Janeiro
val RioBlue = Color(0xFF0066CC)
val RioGreen = Color(0xFF009B3A)
val RioYellow = Color(0xFFFFDD00)

// Cores para níveis de alerta
val AlertLevelGreen = Color(0xFF4CAF50)
val AlertLevelYellow = Color(0xFFFFEB3B)
val AlertLevelOrange = Color(0xFFFF9800)
val AlertLevelRed = Color(0xFFF44336)
val AlertLevelCritical = Color(0xFFB71C1C)

// Cores para condições climáticas
val WeatherSunny = Color(0xFFFFD54F)
val WeatherCloudy = Color(0xFF90A4AE)
val WeatherRainy = Color(0xFF5C6BC0)
val WeatherStormy = Color(0xFF424242)

// Cores para status
val StatusOnline = Color(0xFF4CAF50)
val StatusOffline = Color(0xFFF44336)
val StatusWarning = Color(0xFFFF9800)
val StatusUnknown = Color(0xFF9E9E9E)

// Cores para tipos de eventos
val EventSports = Color(0xFF4CAF50)
val EventMusic = Color(0xFF9C27B0)
val EventCultural = Color(0xFFFF9800)
val EventEducation = Color(0xFF2196F3)
val EventFood = Color(0xFFFF5722)
val EventReligious = Color(0xFF795548)
val EventPolitical = Color(0xFF607D8B)
val EventGeneral = Color(0xFF9E9E9E)

// Cores de fundo para diferentes momentos do dia
val DawnColor = Color(0xFF4A148C)
val MorningColor = Color(0xFF87CEEB)
val AfternoonColor = Color(0xFF2196F3)
val EveningColor = Color(0xFFFF6F00)
val NightColor = Color(0xFF1A237E)

// Cores de overlay e transparências
val OverlayDark = Color(0x99000000)
val OverlayLight = Color(0x33FFFFFF)
val GlassOverlay = Color(0x1AFFFFFF)

// Cores para mapas
val MapWater = Color(0xFF2196F3)
val MapLand = Color(0xFF66BB6A)
val MapRoad = Color(0xFF757575)
val MapBuilding = Color(0xFFBDBDBD)
val MapDanger = Color(0x80F44336)

// Cores de texto
val TextPrimary = Color(0xDE000000)
val TextSecondary = Color(0x99000000)
val TextDisabled = Color(0x61000000)
val TextPrimaryOnDark = Color(0xFFFFFFFF)
val TextSecondaryOnDark = Color(0xB3FFFFFF)

// Função helper para obter cor baseada em porcentagem (ex: nível de chuva)
fun getColorByPercentage(percentage: Float): Color {
    return when {
        percentage < 0.25f -> AlertLevelGreen
        percentage < 0.5f -> AlertLevelYellow
        percentage < 0.75f -> AlertLevelOrange
        else -> AlertLevelRed
    }
}

// Função para obter cor de severidade
fun getSeverityColor(severity: String): Color {
    return when (severity.lowercase()) {
        "baixa", "low" -> AlertLevelGreen
        "média", "medium" -> AlertLevelYellow
        "alta", "high" -> AlertLevelOrange
        "crítica", "critical" -> AlertLevelCritical
        else -> StatusUnknown
    }
}