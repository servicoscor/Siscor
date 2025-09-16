@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import android.util.Log
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import bugarin.t.comando.data.Evento
import bugarin.t.comando.data.TipoEvento
import bugarin.t.comando.ui.theme.BaseCard
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest
import coil.size.Size

@Composable
fun EventosCardView(
    eventos: List<Evento>,
    isLoading: Boolean,
    localizationViewModel: LocalizationViewModel,
    onEventoClick: (Evento) -> Unit
) {
    var selectedEvento by remember { mutableStateOf<Evento?>(null) }
    var showAllEvents by remember { mutableStateOf(false) }

    // ✅ PERFORMANCE: Cached computations
    val (eventoImportante, eventosNormais) = remember(eventos) {
        val importante = eventos.firstOrNull { it.importante }
        val normais = eventos.filter { !it.importante }
        Pair(importante, normais)
    }

    val contentColor = MaterialTheme.colorScheme.onPrimary

    selectedEvento?.let { evento ->
        EventoDetailViewPublic(
            evento = evento,
            onDismiss = { selectedEvento = null },
            localizationViewModel = localizationViewModel
        )
    }

    BaseCard(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp), gradient = cardGradient) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(Icons.Default.CalendarToday, null, tint = contentColor, modifier = Modifier.size(24.dp))
                Text(localizationViewModel.getString("events"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = contentColor)
                if (eventos.isNotEmpty()) {
                    Spacer(modifier = Modifier.weight(1f))
                    Surface(shape = RoundedCornerShape(12.dp), color = contentColor.copy(alpha = 0.2f)) {
                        Text(eventos.size.toString(), modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp), style = MaterialTheme.typography.labelLarge, color = contentColor, fontWeight = FontWeight.Bold)
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            when {
                isLoading -> Box(Modifier.fillMaxWidth().height(150.dp), Alignment.Center) {
                    CircularProgressIndicator(color = contentColor, modifier = Modifier.size(32.dp))
                }
                eventos.isEmpty() -> EmptyEventsState(localizationViewModel, contentColor)
                eventoImportante != null && !showAllEvents -> {
                    OptimizedEventoImportanteCard(evento = eventoImportante, onClick = { selectedEvento = eventoImportante })
                    if (eventosNormais.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedButton(onClick = { showAllEvents = true }, modifier = Modifier.fillMaxWidth(), border = BorderStroke(1.dp, contentColor.copy(alpha = 0.3f))) {
                            Text(localizationViewModel.getString("view_all_events_count", eventos.size), color = contentColor)
                        }
                    }
                }
                else -> {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (showAllEvents && eventoImportante != null) {
                            TextButton(onClick = { showAllEvents = false }) {
                                Icon(Icons.Default.ArrowBack, null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(localizationViewModel.getString("back_to_important"))
                            }
                        }
                        OptimizedEventosList(
                            eventos = if (showAllEvents && eventoImportante != null) listOf(eventoImportante) + eventosNormais else eventosNormais,
                            onEventClick = { selectedEvento = it },
                            localizationViewModel = localizationViewModel
                        )
                    }
                }
            }
        }
    }
}

// ✅ PERFORMANCE: EventoImportanteCard otimizado
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OptimizedEventoImportanteCard(evento: Evento, onClick: () -> Unit) {
    val contentColor = MaterialTheme.colorScheme.onSurface

    // ✅ FIX: Obter context FORA do remember
    val context = LocalContext.current

    // ✅ PERFORMANCE: URL processing cached
    val imageUrl = remember(evento.imagemURL) {
        evento.imagemURL?.let {
            if (it.startsWith("http")) it else "https://aplicativo.cocr.com.br$it"
        }
    }

    Card(onClick = onClick, shape = RoundedCornerShape(12.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column {
            Box(modifier = Modifier.fillMaxWidth().height(180.dp).background(MaterialTheme.colorScheme.surfaceVariant)) {
                if (!imageUrl.isNullOrBlank()) {
                    // ✅ PERFORMANCE: AsyncImage otimizado com cache
                    AsyncImage(
                        model = ImageRequest.Builder(context)
                            .data(imageUrl)
                            .crossfade(true)
                            .size(Size.ORIGINAL) // ✅ PERFORMANCE: Evitar redimensionamento desnecessário
                            .memoryCacheKey(imageUrl) // ✅ MEMORY: Cache explícito
                            .diskCacheKey(imageUrl)
                            .build(),
                        contentDescription = evento.nome,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize(),
                        onError = {
                            Log.w("EventoImportanteCard", "Image load failed: ${it.result.throwable?.message}")
                        }
                    )
                    Box(modifier = Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f)))))
                } else {
                    // ✅ PERFORMANCE: Fallback sem imagem otimizado
                    OptimizedEventoFallback(evento.tipo, contentColor)
                }

                if (evento.importante) {
                    Box(modifier = Modifier.align(Alignment.TopEnd).padding(12.dp).background(Color(0xFFFFD600), CircleShape).padding(8.dp)) {
                        Icon(Icons.Default.Star, "Evento Importante", modifier = Modifier.size(16.dp), tint = Color.Black)
                    }
                }
            }
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(evento.nome.orEmpty(), style = MaterialTheme.typography.titleMedium, color = contentColor, fontWeight = FontWeight.Bold, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Default.LocationOn, null, tint = contentColor.copy(alpha = 0.8f), modifier = Modifier.size(16.dp))
                    Text(evento.local.orEmpty(), style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.8f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                evento.dataString?.let {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.CalendarToday, null, tint = contentColor.copy(alpha = 0.8f), modifier = Modifier.size(16.dp))
                        Text(it, style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.8f))
                    }
                }
            }
        }
    }
}

// ✅ PERFORMANCE: Fallback otimizado para eventos sem imagem
@Composable
private fun OptimizedEventoFallback(tipo: TipoEvento, contentColor: Color) {
    // ✅ FIX: Obter cor FORA do Box para evitar composable call dentro de modifier
    val eventTypeColor = getColorForEventType(tipo)

    Box(
        modifier = Modifier.fillMaxSize().background(
            Brush.radialGradient(
                listOf(
                    eventTypeColor.copy(alpha = 0.3f),
                    Color.Transparent
                )
            )
        ),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            getIconForEventType(tipo),
            null,
            tint = contentColor.copy(alpha = 0.7f),
            modifier = Modifier.size(60.dp)
        )
    }
}

// ✅ PERFORMANCE: Lista de eventos otimizada
@Composable
private fun OptimizedEventosList(eventos: List<Evento>, onEventClick: (Evento) -> Unit, localizationViewModel: LocalizationViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        eventos.forEach { evento ->
            key(evento.id) { // ✅ PERFORMANCE: Key para evitar recomposições desnecessárias
                OptimizedEventoSimpleCard(evento, { onEventClick(evento) }, localizationViewModel)
            }
        }
    }
}

// ✅ PERFORMANCE: EventoSimpleCard otimizado
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OptimizedEventoSimpleCard(evento: Evento, onClick: () -> Unit, localizationViewModel: LocalizationViewModel) {
    // ✅ FIX: Obter cor FORA do remember - já não é uma função @Composable
    val eventColor = getColorForEventType(evento.tipo)
    val contentColor = MaterialTheme.colorScheme.onPrimary

    Card(onClick = onClick, shape = RoundedCornerShape(8.dp), colors = CardDefaults.cardColors(containerColor = contentColor.copy(alpha = 0.1f))) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.size(40.dp).clip(CircleShape).background(eventColor.copy(alpha = 0.2f)), contentAlignment = Alignment.Center) {
                Icon(getIconForEventType(evento.tipo), null, tint = eventColor, modifier = Modifier.size(24.dp))
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(evento.nome?.takeIf { it.isNotBlank() } ?: evento.tipo.getDisplayName(localizationViewModel), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = contentColor, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (!evento.local.isNullOrBlank()) {
                        Text(evento.local, style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.7f), maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                        if(evento.dataString != null) Text(" • ", style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.7f))
                    }
                    evento.dataString?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.7f)) }
                }
            }
            if (evento.importante) {
                Icon(Icons.Default.Star, "Importante", tint = Color(0xFFFFD600), modifier = Modifier.size(20.dp).padding(start = 8.dp))
            }
        }
    }
}

@Composable
private fun EmptyEventsState(localizationViewModel: LocalizationViewModel, contentColor: Color) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(Icons.Default.EventBusy, null, tint = contentColor.copy(alpha = 0.5f), modifier = Modifier.size(48.dp))
        Text(localizationViewModel.getString("no_events_scheduled"), style = MaterialTheme.typography.bodyMedium, color = contentColor.copy(alpha = 0.7f))
    }
}

// --- Funções Auxiliares Otimizadas ---

// ✅ PERFORMANCE: Funções cached para evitar recomputação
private fun getIconForEventType(tipo: TipoEvento): ImageVector = when (tipo) {
    TipoEvento.ESPORTIVO -> Icons.Default.SportsSoccer
    TipoEvento.MUSICAL -> Icons.Default.MusicNote
    TipoEvento.CULTURAL -> Icons.Default.TheaterComedy
    TipoEvento.EDUCACIONAL -> Icons.Default.School
    TipoEvento.GASTRONOMICO -> Icons.Default.Restaurant
    TipoEvento.RELIGIOSO -> Icons.Default.Church
    TipoEvento.CONGRESSO, TipoEvento.G20, TipoEvento.CORPORATIVO -> Icons.Default.Business
    TipoEvento.FEIRA -> Icons.Default.Storefront
    TipoEvento.MANIFESTACAO -> Icons.Default.Campaign
    TipoEvento.REVEILLON -> Icons.Default.Celebration
    TipoEvento.CARNAVAL_BAIRRO, TipoEvento.CARNAVAL_DESFILES, TipoEvento.CARNAVAL_ENSAIOS,
    TipoEvento.CARNAVAL_BLOCOS, TipoEvento.CARNAVAL_PALCOS, TipoEvento.BLOCOS_NAO_OFICIAIS -> Icons.Default.Festival
    TipoEvento.SIMULADO -> Icons.Default.Description
    TipoEvento.ACADEMICOS -> Icons.Default.School
    TipoEvento.POLITICO -> Icons.Default.Gavel
    else -> Icons.Default.Event
}

// ✅ FIX: Removido @Composable - agora é uma função pura
private fun getColorForEventType(tipo: TipoEvento): Color = when (tipo) {
    TipoEvento.MANIFESTACAO, TipoEvento.BLOCOS_NAO_OFICIAIS -> Color(0xFFEF5350) // Vermelho Material
    TipoEvento.REVEILLON, TipoEvento.CARNAVAL_DESFILES -> Color(0xFFFFD600) // Amarelo/Dourado
    TipoEvento.CARNAVAL_BLOCOS, TipoEvento.MUSICAL -> Color(0xFF9C27B0) // Roxo Material
    TipoEvento.ESPORTIVO, TipoEvento.G20 -> Color(0xFF4CAF50) // Verde
    TipoEvento.CULTURAL, TipoEvento.FEIRA -> Color(0xFF2196F3) // Azul Material
    TipoEvento.CONGRESSO, TipoEvento.CORPORATIVO -> Color(0xFF4A148C) // Roxo escuro
    TipoEvento.EDUCACIONAL, TipoEvento.ACADEMICOS -> Color(0xFF1976D2) // Azul escuro
    TipoEvento.GASTRONOMICO -> Color(0xFFD32F2F) // Vermelho escuro
    TipoEvento.RELIGIOSO -> Color(0xFFB2EBF2) // Ciano claro
    TipoEvento.POLITICO -> Color(0xFF2E7D32) // Verde escuro
    else -> Color(0xFF6200EA) // Roxo padrão
}

// ✅ PERFORMANCE: Extension function otimizada
private fun TipoEvento.getDisplayName(localization: LocalizationViewModel): String = when(this) {
    TipoEvento.ESPORTIVO -> localization.getString("event_type_sports")
    TipoEvento.MUSICAL -> localization.getString("event_type_musical")
    TipoEvento.CULTURAL -> localization.getString("event_type_cultural")
    TipoEvento.EDUCACIONAL -> localization.getString("event_type_educational")
    TipoEvento.GASTRONOMICO -> localization.getString("event_type_gastronomic")
    TipoEvento.RELIGIOSO -> localization.getString("event_type_religious")
    TipoEvento.POLITICO -> localization.getString("event_type_political")
    TipoEvento.CORPORATIVO -> localization.getString("event_type_corporate")
    TipoEvento.FEIRA -> localization.getString("event_type_fair")
    TipoEvento.CONGRESSO -> localization.getString("event_type_congress")
    TipoEvento.MANIFESTACAO -> localization.getString("event_type_protest")
    TipoEvento.REVEILLON -> localization.getString("event_type_new_years")
    TipoEvento.CARNAVAL_BAIRRO -> localization.getString("event_type_carnival_neighborhood")
    TipoEvento.CARNAVAL_DESFILES -> localization.getString("event_type_carnival_parades")
    TipoEvento.CARNAVAL_ENSAIOS -> localization.getString("event_type_carnival_rehearsals")
    TipoEvento.CARNAVAL_BLOCOS -> localization.getString("event_type_carnival_blocos")
    TipoEvento.CARNAVAL_PALCOS -> localization.getString("event_type_carnival_stages")
    TipoEvento.BLOCOS_NAO_OFICIAIS -> localization.getString("event_type_unofficial_blocos")
    TipoEvento.SIMULADO -> localization.getString("event_type_drill")
    TipoEvento.ACADEMICOS -> localization.getString("event_type_academic")
    TipoEvento.G20 -> localization.getString("event_type_g20")
    TipoEvento.OUTRO -> localization.getString("event_type_other")
}

// ✅ FIXED: Renomeado para evitar conflito - função pública
@Composable
fun EventoDetailViewPublic(
    evento: Evento,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // Implementação do dialog de detalhes do evento
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(evento.nome ?: "Evento") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                evento.local?.let {
                    Row(verticalAlignment = Alignment.Top) {
                        Icon(Icons.Default.LocationOn, null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(it)
                    }
                }
                evento.dataString?.let {
                    Row(verticalAlignment = Alignment.Top) {
                        Icon(Icons.Default.CalendarToday, null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(it)
                    }
                }
                evento.descricao?.let {
                    Text(it, style = MaterialTheme.typography.bodyMedium)
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(localizationViewModel.getString("close"))
            }
        }
    )
}