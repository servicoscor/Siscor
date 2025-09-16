@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import bugarin.t.comando.data.Evento
import bugarin.t.comando.data.TipoEvento
import bugarin.t.comando.viewmodel.LocalizationViewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun EventoDetailView(
    evento: Evento,
    onDismiss: () -> Unit,
    // ✅ LOCALIZATION: ViewModel agora é um parâmetro obrigatório.
    localizationViewModel: LocalizationViewModel
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false),
        windowInsets = WindowInsets(0.dp)
    ) {
        Column(modifier = Modifier.fillMaxHeight(0.9f).verticalScroll(scrollState)) {
            // Header
            HeaderEvento(evento, onDismiss, localizationViewModel)

            // Conteúdo
            Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                // Data e Hora
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        evento.data?.let { data ->
                            // ✅ LOCALIZATION: Locale da data agora é o padrão do sistema (controlado pelo ProvideLocalizedContext).
                            val formattedDate = SimpleDateFormat("EEEE, dd 'de' MMMM 'de' yyyy", Locale.getDefault()).format(data)
                            InfoRow(Icons.Default.CalendarToday, localizationViewModel.getString("date"), formattedDate)
                        }
                        if (evento.horaInicio != null || evento.horaEncerramento != null) {
                            val timeString = buildString {
                                evento.horaInicio?.let { append(it) }
                                if (evento.horaInicio != null && evento.horaEncerramento != null) append(" às ")
                                evento.horaEncerramento?.let { append(it) }
                            }
                            InfoRow(Icons.Default.AccessTime, localizationViewModel.getString("time"), timeString)
                        }
                    }
                }

                // Local e Mapa
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        evento.local?.let { InfoRow(Icons.Default.LocationOn, localizationViewModel.getString("location"), it) }
                        evento.zona?.let { InfoRow(Icons.Default.Map, localizationViewModel.getString("zone"), it) }

                        // Corrigido: Cria variáveis locais para evitar smart cast issues
                        val lat = evento.lat
                        val lon = evento.lon
                        if (lat != null && lon != null) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Card(modifier = Modifier.fillMaxWidth().height(150.dp), shape = RoundedCornerShape(8.dp)) {
                                SimpleMapCard(location = LatLng(lat, lon), markerTitle = evento.nome)
                            }
                        }
                    }
                }

                // Descrição
                evento.descricao?.let {
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Icon(Icons.Default.Description, null, tint = MaterialTheme.colorScheme.primary)
                                Text(localizationViewModel.getString("description"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(it, style = MaterialTheme.typography.bodyLarge)
                        }
                    }
                }

                // Botões de Ação
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = { shareEvento(context, evento, localizationViewModel) }, modifier = Modifier.weight(1f)) {
                        Icon(Icons.Default.Share, null, Modifier.size(18.dp)); Spacer(Modifier.width(8.dp)); Text(localizationViewModel.getString("share"))
                    }
                    if (evento.lat != null && evento.lon != null) {
                        Button(onClick = { openInMaps(context, evento) }, modifier = Modifier.weight(1f)) {
                            Icon(Icons.Default.Directions, null, Modifier.size(18.dp)); Spacer(Modifier.width(8.dp)); Text(localizationViewModel.getString("get_directions"))
                        }
                    }
                }
                Spacer(modifier = Modifier.navigationBarsPadding())
            }
        }
    }
}

@Composable
private fun HeaderEvento(evento: Evento, onDismiss: () -> Unit, localizationViewModel: LocalizationViewModel) {
    val eventColor = getColorForEventType(evento.tipo)
    val contentColor = Color.White // ✅ TEMATIZAÇÃO: Cor branca é intencional para contraste com o gradiente.

    Box(modifier = Modifier.background(Brush.verticalGradient(listOf(eventColor, eventColor.copy(alpha = 0.8f))))) {
        Column {
            Row(modifier = Modifier.fillMaxWidth().statusBarsPadding().padding(16.dp), verticalAlignment = Alignment.Top) {
                Column(modifier = Modifier.weight(1f)) {
                    if (evento.importante) {
                        // ✅ TEMATIZAÇÃO: Badge com cores semânticas.
                        Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.tertiaryContainer) {
                            Row(modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                Icon(Icons.Default.Star, null, tint = MaterialTheme.colorScheme.onTertiaryContainer, modifier = Modifier.size(16.dp))
                                Text(localizationViewModel.getString("important").uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onTertiaryContainer)
                            }
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    Text(evento.nome.orEmpty(), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = contentColor)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(getEventTypeDisplayName(evento.tipo, localizationViewModel), style = MaterialTheme.typography.labelLarge, color = contentColor.copy(alpha = 0.9f))
                }
                IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, localizationViewModel.getString("close"), tint = contentColor) }
            }
            Box(modifier = Modifier.fillMaxWidth().height(180.dp).background(Color.Black.copy(alpha = 0.2f)), contentAlignment = Alignment.Center) {
                val imageUrl = evento.imagemURL?.let { if (it.startsWith("http")) it else "https://aplicativo.cocr.com.br$it" }
                if (!imageUrl.isNullOrBlank()) {
                    AsyncImage(model = ImageRequest.Builder(LocalContext.current).data(imageUrl).crossfade(true).build(), contentDescription = evento.nome, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                    Box(modifier = Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.5f)))))
                } else {
                    Icon(getIconForEventType(evento.tipo), null, tint = contentColor.copy(alpha = 0.5f), modifier = Modifier.size(60.dp))
                }
            }
        }
    }
}

@Composable
private fun InfoRow(icon: ImageVector, label: String, value: String, valueColor: Color = MaterialTheme.colorScheme.onSurface) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp).padding(top = 2.dp))
        Column {
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, style = MaterialTheme.typography.bodyLarge, color = valueColor)
        }
    }
}

@Composable
private fun SimpleMapCard(
    location: LatLng,
    markerTitle: String?
) {
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(location, 15f)
    }

    GoogleMap(
        modifier = Modifier.fillMaxSize(),
        cameraPositionState = cameraPositionState,
        properties = MapProperties(isMyLocationEnabled = false),
        uiSettings = MapUiSettings(
            zoomControlsEnabled = false,
            myLocationButtonEnabled = false,
            mapToolbarEnabled = false,
            compassEnabled = false,
            rotationGesturesEnabled = false,
            scrollGesturesEnabled = false,
            tiltGesturesEnabled = false,
            zoomGesturesEnabled = false
        )
    ) {
        Marker(
            state = MarkerState(position = location),
            title = markerTitle
        )
    }
}

private fun shareEvento(context: Context, evento: Evento, localizationViewModel: LocalizationViewModel) {
    val shareText = buildString {
        appendLine("📅 ${evento.nome ?: localizationViewModel.getString("event")}")
        evento.data?.let { appendLine("📆 ${SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()).format(it)}") }
        evento.horaInicio?.let { appendLine("🕐 $it") }
        evento.local?.let { appendLine("📍 $it") }
    }
    val intent = Intent(Intent.ACTION_SEND).apply { action = Intent.ACTION_SEND; putExtra(Intent.EXTRA_TEXT, shareText); type = "text/plain" }
    context.startActivity(Intent.createChooser(intent, localizationViewModel.getString("share_event")))
}

private fun openInMaps(context: Context, evento: Evento) {
    val lat = evento.lat
    val lon = evento.lon
    if (lat != null && lon != null) {
        val uri = Uri.parse("geo:$lat,$lon?q=$lat,$lon(${Uri.encode(evento.nome)})")
        val intent = Intent(Intent.ACTION_VIEW, uri).setPackage("com.google.android.apps.maps")
        context.startActivity(intent)
    }
}

// Helper functions para TipoEvento
private fun getColorForEventType(type: TipoEvento): Color {
    return when (type) {
        TipoEvento.CULTURAL -> Color(0xFF9C27B0)
        TipoEvento.ESPORTIVO -> Color(0xFF2196F3)
        TipoEvento.EDUCACIONAL -> Color(0xFF4CAF50)
        TipoEvento.MUSICAL -> Color(0xFFFF9800)
        TipoEvento.GASTRONOMICO -> Color(0xFFE91E63)
        TipoEvento.CONGRESSO -> Color(0xFF00BCD4)
        TipoEvento.FEIRA -> Color(0xFF795548)
        TipoEvento.MANIFESTACAO -> Color(0xFFF44336)
        TipoEvento.RELIGIOSO -> Color(0xFF3F51B5)
        TipoEvento.REVEILLON -> Color(0xFFFFEB3B)
        TipoEvento.CARNAVAL_BAIRRO -> Color(0xFFFF5722)
        TipoEvento.CARNAVAL_DESFILES -> Color(0xFFFF6F00)
        TipoEvento.CARNAVAL_ENSAIOS -> Color(0xFFFF8F00)
        TipoEvento.CARNAVAL_BLOCOS -> Color(0xFFFFA000)
        TipoEvento.CARNAVAL_PALCOS -> Color(0xFFFFB300)
        TipoEvento.BLOCOS_NAO_OFICIAIS -> Color(0xFFFFC107)
        TipoEvento.SIMULADO -> Color(0xFF9E9E9E)
        TipoEvento.ACADEMICOS -> Color(0xFF673AB7)
        TipoEvento.G20 -> Color(0xFF1976D2)
        TipoEvento.CORPORATIVO -> Color(0xFF455A64)
        TipoEvento.POLITICO -> Color(0xFF616161)
        TipoEvento.OUTRO -> Color(0xFF607D8B)
    }
}

private fun getIconForEventType(type: TipoEvento): ImageVector {
    return when (type) {
        TipoEvento.CULTURAL -> Icons.Default.TheaterComedy
        TipoEvento.ESPORTIVO -> Icons.Default.SportsSoccer
        TipoEvento.EDUCACIONAL -> Icons.Default.School
        TipoEvento.MUSICAL -> Icons.Default.MusicNote
        TipoEvento.GASTRONOMICO -> Icons.Default.Restaurant
        TipoEvento.CONGRESSO -> Icons.Default.Groups
        TipoEvento.FEIRA -> Icons.Default.Store
        TipoEvento.MANIFESTACAO -> Icons.Default.Campaign
        TipoEvento.RELIGIOSO -> Icons.Default.Church
        TipoEvento.REVEILLON -> Icons.Default.Celebration
        TipoEvento.CARNAVAL_BAIRRO,
        TipoEvento.CARNAVAL_DESFILES,
        TipoEvento.CARNAVAL_ENSAIOS,
        TipoEvento.CARNAVAL_BLOCOS,
        TipoEvento.CARNAVAL_PALCOS,
        TipoEvento.BLOCOS_NAO_OFICIAIS -> Icons.Default.Festival
        TipoEvento.SIMULADO -> Icons.Default.Warning
        TipoEvento.ACADEMICOS -> Icons.Default.MenuBook
        TipoEvento.G20 -> Icons.Default.Public
        TipoEvento.CORPORATIVO -> Icons.Default.Business
        TipoEvento.POLITICO -> Icons.Default.HowToVote
        TipoEvento.OUTRO -> Icons.Default.Event
    }
}

private fun getEventTypeDisplayName(type: TipoEvento, localizationViewModel: LocalizationViewModel): String {
    return when (type) {
        TipoEvento.CULTURAL -> localizationViewModel.getString("event_type_cultural")
        TipoEvento.ESPORTIVO -> localizationViewModel.getString("event_type_sport")
        TipoEvento.EDUCACIONAL -> localizationViewModel.getString("event_type_education")
        TipoEvento.MUSICAL -> localizationViewModel.getString("event_type_musical")
        TipoEvento.GASTRONOMICO -> localizationViewModel.getString("event_type_gastronomic")
        TipoEvento.CONGRESSO -> localizationViewModel.getString("event_type_congress")
        TipoEvento.FEIRA -> localizationViewModel.getString("event_type_fair")
        TipoEvento.MANIFESTACAO -> localizationViewModel.getString("event_type_manifestation")
        TipoEvento.RELIGIOSO -> localizationViewModel.getString("event_type_religious")
        TipoEvento.REVEILLON -> localizationViewModel.getString("event_type_new_year")
        TipoEvento.CARNAVAL_BAIRRO -> localizationViewModel.getString("event_type_carnival_neighborhood")
        TipoEvento.CARNAVAL_DESFILES -> localizationViewModel.getString("event_type_carnival_parades")
        TipoEvento.CARNAVAL_ENSAIOS -> localizationViewModel.getString("event_type_carnival_rehearsals")
        TipoEvento.CARNAVAL_BLOCOS -> localizationViewModel.getString("event_type_carnival_blocks")
        TipoEvento.CARNAVAL_PALCOS -> localizationViewModel.getString("event_type_carnival_stages")
        TipoEvento.BLOCOS_NAO_OFICIAIS -> localizationViewModel.getString("event_type_unofficial_blocks")
        TipoEvento.SIMULADO -> localizationViewModel.getString("event_type_simulation")
        TipoEvento.ACADEMICOS -> localizationViewModel.getString("event_type_academic")
        TipoEvento.G20 -> localizationViewModel.getString("event_type_g20")
        TipoEvento.CORPORATIVO -> localizationViewModel.getString("event_type_corporate")
        TipoEvento.POLITICO -> localizationViewModel.getString("event_type_political")
        TipoEvento.OUTRO -> localizationViewModel.getString("event_type_others")
    }
}