package bugarin.t.comando.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import bugarin.t.comando.R
import bugarin.t.comando.viewmodel.LocalizationViewModel

/**
 * ✅ ARQUITETURA: O HeaderView agora é implementado como um TopAppBar.
 * Para usá-lo, coloque-o no slot 'topBar' de um Scaffold na sua MainScreen.
 * Ex: Scaffold(topBar = { HeaderView(...) }) { padding -> ... }
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HeaderView(
    currentStage: Int = 1,
    alertCount: Int = 0,
    eventCount: Int = 0,
    scrollToAlerts: () -> Unit = {},
    scrollToEvents: () -> Unit = {},
    localizationViewModel: LocalizationViewModel,
    modifier: Modifier = Modifier
) {
    var showLanguageMenu by remember { mutableStateOf(false) }
    val currentLanguage by localizationViewModel.currentLanguage.collectAsState()
    val stageColor = getColorForStage(currentStage)

    val infiniteTransition = rememberInfiniteTransition(label = "HeaderPulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "PulseScale"
    )

    TopAppBar(
        modifier = modifier,
        title = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Indicador de status pulsante
                Box(contentAlignment = Alignment.Center) {
                    Box(modifier = Modifier.size(8.dp).scale(pulseScale).alpha(1.2f - pulseScale).background(stageColor, CircleShape))
                    Box(modifier = Modifier.size(8.dp).background(stageColor, CircleShape))
                }
                Image(
                    painter = painterResource(id = R.drawable.logocordeitado),
                    contentDescription = "Logo Prefeitura Rio",
                    modifier = Modifier.height(24.dp)
                )
            }
        },
        actions = {
            // Seletor de Idioma
            Box {
                IconButton(onClick = { showLanguageMenu = true }) {
                    Text(text = getCurrentLanguageFlag(currentLanguage), fontSize = 20.sp)
                }
                DropdownMenu(expanded = showLanguageMenu, onDismissRequest = { showLanguageMenu = false }) {
                    LocalizationViewModel.supportedLanguages.forEach { language ->
                        DropdownMenuItem(
                            text = {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text(text = language.flag, fontSize = 20.sp)
                                    Text(text = language.name, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                                    if (currentLanguage == language.code) {
                                        Icon(Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.primary)
                                    }
                                }
                            },
                            onClick = {
                                localizationViewModel.setLanguage(language.code)
                                showLanguageMenu = false
                            }
                        )
                    }
                }
            }


            // Botão de Alertas com Badge
            BadgedBox(
                badge = {
                    if (alertCount > 0) {
                        Badge(containerColor = MaterialTheme.colorScheme.error) {
                            Text(alertCount.toString())
                        }
                    }
                }
            ) {
                IconButton(onClick = scrollToAlerts) {
                    Icon(
                        imageVector = if (alertCount > 0) Icons.Default.NotificationsActive else Icons.Default.NotificationsNone,
                        contentDescription = localizationViewModel.getString("alerts"),
                        tint = if (alertCount > 0) MaterialTheme.colorScheme.error else LocalContentColor.current
                    )
                }
            }
        },
        // ✅ TEMATIZAÇÃO: Cores controladas pelo tema do Material Design.
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = Color(0xFF2E2E2E), // Cinza escuro
            titleContentColor = Color.White, // Texto branco para contraste
            actionIconContentColor = Color.White // Ícones brancos para contraste
        )
    )
}

@Composable
private fun getColorForStage(stage: Int): Color = when (stage) {
    // ✅ TEMATIZAÇÃO: Cores semânticas do tema.
    1 -> Color(0xFF4CAF50) // Verde (Mantido por ser cor de marca/status)
    2 -> Color(0xFFFFC107) // Amarelo (Mantido por ser cor de marca/status)
    3 -> Color(0xFFFF9800) // Laranja (Mantido por ser cor de marca/status)
    4 -> MaterialTheme.colorScheme.error // Vermelho
    5 -> MaterialTheme.colorScheme.tertiary // Roxo/Outra cor
    else -> MaterialTheme.colorScheme.outline
}

private fun getCurrentLanguageFlag(languageCode: String): String {
    return LocalizationViewModel.supportedLanguages
        .find { it.code == languageCode }?.flag ?: "🌐"
}