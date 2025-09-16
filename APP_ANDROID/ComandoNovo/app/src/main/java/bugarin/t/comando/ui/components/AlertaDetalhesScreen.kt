package bugarin.t.comando.ui.screens

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import bugarin.t.comando.data.Alerta
import bugarin.t.comando.viewmodel.LocalizationViewModel
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertaDetalhesScreen(
    alerta: Alerta,
    onBack: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val context = LocalContext.current
    var isPlaying by remember { mutableStateOf(false) }
    val mediaPlayer = remember { MediaPlayer() }

    // Palavras-chave para destaque definidas inline
    val palavrasDestaque = remember {
        listOf(
            "ATENÇÃO", "URGENTE", "ALERTA", "PERIGO", "CUIDADO",
            "EVACUAÇÃO", "EMERGÊNCIA", "IMEDIATO", "CRÍTICO"
        )
    }

    // ✅ FIX: Cleanup mais robusto do MediaPlayer
    DisposableEffect(Unit) {
        onDispose {
            try {
                if (isPlaying) {
                    mediaPlayer.stop()
                }
                mediaPlayer.reset()
                mediaPlayer.release()
                android.util.Log.d("AlertaDetalhesScreen", "MediaPlayer resources cleaned up")
            } catch (e: Exception) {
                android.util.Log.e("AlertaDetalhesScreen", "Error cleaning up MediaPlayer: ${e.message}")
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(alerta.nome ?: localizationViewModel.getString("alert_details"), maxLines = 1) },
                navigationIcon = {
                    IconButton(onClick = {
                        try {
                            onBack()
                        } catch (e: Exception) {
                            android.util.Log.e("AlertaDetalhesScreen", "Error in back navigation: ${e.message}")
                        }
                    }) {
                        Icon(Icons.Default.ArrowBack, localizationViewModel.getString("back"))
                    }
                },
                actions = {
                    IconButton(onClick = {
                        shareAlert(context, alerta, localizationViewModel)
                    }) {
                        Icon(Icons.Default.Share, localizationViewModel.getString("share"))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.error,
                    titleContentColor = MaterialTheme.colorScheme.onError,
                    navigationIconContentColor = MaterialTheme.colorScheme.onError,
                    actionIconContentColor = MaterialTheme.colorScheme.onError
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            alerta.mensagem?.let {
                Card(shape = RoundedCornerShape(16.dp)) {
                    Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Icon(Icons.Default.Message, null, tint = MaterialTheme.colorScheme.primary)
                            Text(localizationViewModel.getString("message"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        }
                        HorizontalDivider()
                        Text(highlightText(it, palavrasDestaque), style = MaterialTheme.typography.bodyLarge.copy(lineHeight = 24.sp))
                    }
                }
            }

            alerta.audiourl?.let { audioUrl ->
                Card(shape = RoundedCornerShape(16.dp)) {
                    Row(
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(localizationViewModel.getString("audio_alert"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            Text(localizationViewModel.getString("tap_to_play"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        FilledTonalIconButton(
                            onClick = {
                                toggleAudioPlayback(mediaPlayer, audioUrl, isPlaying) { newPlayingState ->
                                    isPlaying = newPlayingState
                                }
                            },
                            modifier = Modifier.size(56.dp)
                        ) {
                            Icon(if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow, null, modifier = Modifier.size(32.dp))
                        }
                    }
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = { shareAlert(context, alerta, localizationViewModel) },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(Icons.Default.Share, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(localizationViewModel.getString("share"))
                }
                Button(
                    onClick = {
                        try {
                            onBack()
                        } catch (e: Exception) {
                            android.util.Log.e("AlertaDetalhesScreen", "Error in close button: ${e.message}")
                        }
                    },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(localizationViewModel.getString("close"))
                }
            }
        }
    }
}

@Composable
private fun highlightText(text: String, keywords: List<String>): androidx.compose.ui.text.AnnotatedString {
    return buildAnnotatedString {
        val highlightStyle = SpanStyle(
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.Bold,
            background = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)
        )
        val pattern = keywords.joinToString("|") { Regex.escape(it) }.toRegex(RegexOption.IGNORE_CASE)
        var lastIndex = 0
        pattern.findAll(text).forEach { matchResult ->
            if (lastIndex < matchResult.range.first) {
                append(text.substring(lastIndex, matchResult.range.first))
            }
            withStyle(style = highlightStyle) {
                append(matchResult.value)
            }
            lastIndex = matchResult.range.last + 1
        }
        if (lastIndex < text.length) {
            append(text.substring(lastIndex))
        }
    }
}

// ✅ FIX: Função de áudio mais robusta
private fun toggleAudioPlayback(
    mediaPlayer: MediaPlayer,
    audioUrl: String,
    isPlaying: Boolean,
    onPlayingChange: (Boolean) -> Unit
) {
    try {
        if (isPlaying) {
            // Parar áudio
            if (mediaPlayer.isPlaying) {
                mediaPlayer.pause()
            }
            onPlayingChange(false)
            android.util.Log.d("AlertaDetalhesScreen", "Audio paused")
        } else {
            // Iniciar áudio
            mediaPlayer.reset()

            // ✅ Verificar se URL é válida
            if (audioUrl.isBlank() || (!audioUrl.startsWith("http://") && !audioUrl.startsWith("https://"))) {
                android.util.Log.w("AlertaDetalhesScreen", "Invalid audio URL: $audioUrl")
                onPlayingChange(false)
                return
            }

            mediaPlayer.setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build()
            )

            mediaPlayer.setDataSource(audioUrl)
            mediaPlayer.prepareAsync()

            mediaPlayer.setOnPreparedListener { player ->
                try {
                    player.start()
                    onPlayingChange(true)
                    android.util.Log.d("AlertaDetalhesScreen", "Audio started successfully")
                } catch (e: Exception) {
                    android.util.Log.e("AlertaDetalhesScreen", "Error starting audio: ${e.message}")
                    onPlayingChange(false)
                }
            }

            mediaPlayer.setOnCompletionListener {
                onPlayingChange(false)
                android.util.Log.d("AlertaDetalhesScreen", "Audio completed")
            }

            mediaPlayer.setOnErrorListener { _, what, extra ->
                android.util.Log.e("AlertaDetalhesScreen", "MediaPlayer error: what=$what, extra=$extra")
                onPlayingChange(false)
                true // Indica que o erro foi tratado
            }
        }
    } catch (e: Exception) {
        android.util.Log.e("AlertaDetalhesScreen", "Error in audio playback: ${e.message}")
        onPlayingChange(false)
    }
}

private fun formatarDataRelativa(dataString: String): String {
    val format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
    return try {
        val date = format.parse(dataString) ?: return dataString
        val now = Date()
        val diffMinutes = TimeUnit.MILLISECONDS.toMinutes(now.time - date.time)
        when {
            diffMinutes < 60 -> "$diffMinutes min atrás"
            diffMinutes < 1440 -> "${TimeUnit.MINUTES.toHours(diffMinutes)}h atrás"
            else -> SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()).format(date)
        }
    } catch (e: Exception) {
        android.util.Log.w("AlertaDetalhesScreen", "Error formatting date: ${e.message}")
        dataString
    }
}

// ✅ FIX: Função shareAlert com verificações robustas
private fun shareAlert(context: Context, alerta: Alerta, localizationViewModel: LocalizationViewModel) {
    try {
        // ✅ Verificar se context é válido
        if (context !is android.app.Activity) {
            android.util.Log.w("AlertaDetalhesScreen", "Context is not an Activity")
            return
        }

        // ✅ Verificar se Activity não está sendo destruída
        if (context.isFinishing || context.isDestroyed) {
            android.util.Log.w("AlertaDetalhesScreen", "Activity is finishing or destroyed")
            return
        }

        val shareText = buildString {
            appendLine("🚨 ${alerta.nome ?: localizationViewModel.getString("alert")}")
            alerta.data?.let { appendLine("📅 ${formatarDataRelativa(it)}") }
            appendLine()
            append(alerta.mensagem ?: "")
        }

        // ✅ Verificar se o texto não está vazio
        if (shareText.isBlank()) {
            android.util.Log.w("AlertaDetalhesScreen", "Share text is empty")
            return
        }

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
            putExtra(Intent.EXTRA_SUBJECT, alerta.nome ?: localizationViewModel.getString("alert"))
        }

        val chooser = Intent.createChooser(intent, localizationViewModel.getString("share_alert"))

        // ✅ Verificar se há apps que podem lidar com o intent
        if (chooser.resolveActivity(context.packageManager) != null) {
            context.startActivity(chooser)
            android.util.Log.d("AlertaDetalhesScreen", "Share intent started successfully")
        } else {
            android.util.Log.w("AlertaDetalhesScreen", "No app available to handle share intent")
        }

    } catch (e: SecurityException) {
        android.util.Log.e("AlertaDetalhesScreen", "Security exception during share: ${e.message}")
    } catch (e: Exception) {
        android.util.Log.e("AlertaDetalhesScreen", "Error sharing alert: ${e.message}")
    }
}