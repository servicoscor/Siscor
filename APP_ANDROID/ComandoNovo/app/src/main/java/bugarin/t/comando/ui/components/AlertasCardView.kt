package bugarin.t.comando.ui.components

import android.content.Context
import android.content.Intent
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Route
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Traffic
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material.icons.filled.Air
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgeDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import bugarin.t.comando.data.Alerta
import bugarin.t.comando.viewmodel.LocalizationViewModel
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

@Composable
fun AlertasCardView(
    alertas: List<Alerta>,
    isLoading: Boolean,
    onAlertaClick: (Alerta) -> Unit,
    localizationViewModel: LocalizationViewModel,
) {
    var isVisible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { isVisible = true }

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
                .padding(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(Icons.Filled.NotificationsActive, null, tint = contentColor, modifier = Modifier.size(24.dp))
                Text(localizationViewModel.getString("alerts"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = contentColor)
                if (alertas.isNotEmpty()) {
                    Spacer(modifier = Modifier.weight(1f))
                    Badge(containerColor = contentColor.copy(alpha = 0.2f)) {
                        Text(alertas.size.toString(), color = contentColor, fontWeight = FontWeight.Bold)
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            when {
                isLoading -> Box(Modifier.fillMaxWidth().height(120.dp), Alignment.Center) { CircularProgressIndicator(color = contentColor) }
                alertas.isEmpty() -> EmptyStateView(
                    icon = Icons.Default.CheckCircle, // ✅ CORREÇÃO: Passando ImageVector diretamente
                    message = localizationViewModel.getString("no_alerts_active"),
                    contentColor = contentColor
                )
                else -> {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        alertas.forEachIndexed { index, alerta ->
                            AnimatedVisibility(
                                visible = isVisible,
                                enter = slideInHorizontally(
                                    initialOffsetX = { -it }, // Lambda que retorna o offset inicial
                                    animationSpec = tween(300, index * 60)
                                ) + fadeIn(
                                    animationSpec = tween(300, index * 60)
                                )
                            ) {
                                AlertaRow(alerta, localizationViewModel) { onAlertaClick(alerta) }
                            }
                        }

                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AlertaRow(alerta: Alerta, localizationViewModel: LocalizationViewModel, onClick: () -> Unit) {
    val contentColor = MaterialTheme.colorScheme.onPrimary

    Card(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = contentColor.copy(alpha = 0.1f))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(getIconForAlert(alerta), null, modifier = Modifier.size(24.dp), tint = contentColor)
            Column(modifier = Modifier.weight(1f)) {
                Text(alerta.nome ?: localizationViewModel.getString("alert"), style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = contentColor, maxLines = 2)
                alerta.data?.let {
                    Text(formatarDataRelativa(it, localizationViewModel), style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.7f))
                }
            }
            Icon(Icons.Default.ChevronRight, null, tint = contentColor.copy(alpha = 0.7f), modifier = Modifier.size(20.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertaDetalhesBottomSheet(alerta: Alerta, localizationViewModel: LocalizationViewModel, onDismiss: () -> Unit) {
    val context = LocalContext.current
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(modifier = Modifier.navigationBarsPadding().padding(24.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Icon(getIconForAlert(alerta), null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(28.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(alerta.nome ?: localizationViewModel.getString("alert_details"), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    alerta.data?.let { Text(formatarDataCompleta(it), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                }
            }
            HorizontalDivider()
            alerta.mensagem?.let {
                Text(it, style = MaterialTheme.typography.bodyLarge)
            }
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = { shareAlert(context, alerta, localizationViewModel) }, modifier = Modifier.weight(1f)) {
                    Icon(Icons.Default.Share, null, Modifier.size(18.dp)); Spacer(Modifier.width(8.dp)); Text(localizationViewModel.getString("share"))
                }
                Button(onClick = onDismiss, modifier = Modifier.weight(1f)) { Text(localizationViewModel.getString("close")) }
            }
        }
    }
}

private fun getIconForAlert(alerta: Alerta): ImageVector {
    val texto = (alerta.nome ?: "").lowercase()
    return when {
        texto.contains("acidente") -> Icons.Filled.DirectionsCar
        texto.contains("pista") || texto.contains("avenida") -> Icons.Filled.Route
        texto.contains("trânsito") || texto.contains("via") -> Icons.Filled.Traffic
        texto.contains("sirene") -> Icons.Filled.Campaign
        texto.contains("ressaca") -> Icons.Filled.Waves
        texto.contains("chuva") -> Icons.Filled.Umbrella
        texto.contains("vento") -> Icons.Filled.Air
        else -> Icons.Filled.Warning
    }
}

// ✅ IMPLEMENTADO: Lógica de formatação de data relativa e traduzível.
private fun formatarDataRelativa(dataString: String, localizationViewModel: LocalizationViewModel): String {
    val format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
    return try {
        val date = format.parse(dataString) ?: return dataString
        val now = Date()
        val diffMillis = now.time - date.time
        val diffMinutes = TimeUnit.MILLISECONDS.toMinutes(diffMillis)
        val diffHours = TimeUnit.MILLISECONDS.toHours(diffMillis)
        val diffDays = TimeUnit.MILLISECONDS.toDays(diffMillis)

        when {
            diffMinutes < 1 -> localizationViewModel.getString("just_now")
            diffMinutes < 60 -> localizationViewModel.getString("minutes_ago", diffMinutes)
            diffHours < 24 -> localizationViewModel.getString("hours_ago", diffHours)
            diffDays < 2 -> localizationViewModel.getString("yesterday")
            else -> SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()).format(date)
        }
    } catch (e: Exception) {
        dataString // Retorna a string original se o parse falhar
    }
}

// ✅ IMPLEMENTADO: Lógica de formatação de data completa e traduzível.
private fun formatarDataCompleta(dataString: String): String {
    val inputFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
    val outputFormat = SimpleDateFormat("EEEE, dd 'de' MMMM 'de' yyyy, HH:mm", Locale.getDefault())
    return try {
        val date = inputFormat.parse(dataString) ?: return dataString
        outputFormat.format(date).replaceFirstChar { it.uppercase() }
    } catch (e: Exception) {
        dataString
    }
}

private fun shareAlert(context: Context, alerta: Alerta, localizationViewModel: LocalizationViewModel) {
    val shareText = buildString {
        appendLine("🚨 ${alerta.nome ?: localizationViewModel.getString("alert")}")
        alerta.data?.let { appendLine("📅 $it") }
        appendLine()
        append(alerta.mensagem ?: "")
    }
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, shareText)
    }
    context.startActivity(Intent.createChooser(intent, localizationViewModel.getString("share_alert")))
}
