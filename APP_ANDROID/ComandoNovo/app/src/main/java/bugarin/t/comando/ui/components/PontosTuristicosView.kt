@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.navigation.NavController
import bugarin.t.comando.data.CategoriaPonto
import bugarin.t.comando.data.PontoTuristico
import bugarin.t.comando.ui.components.*
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState

private sealed class MapState {
    data object Hidden : MapState()
    data class Visible(val pontos: List<PontoTuristico>, val pontoFocado: PontoTuristico? = null) : MapState()
}

// ✅ FIX: Receber os dados como parâmetros em vez de usar ViewModel
@Composable
fun PontosTuristicosView(
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel,
    pontos: List<PontoTuristico> = emptyList(), // ✅ NOVO: Recebe os dados
    isLoading: Boolean = false // ✅ NOVO: Recebe o estado de loading
) {
    var searchText by remember { mutableStateOf("") }
    var selectedCategoria by remember { mutableStateOf(CategoriaPonto.TODOS) }
    var mapState by remember { mutableStateOf<MapState>(MapState.Hidden) }
    var selectedPonto by remember { mutableStateOf<PontoTuristico?>(null) }
    val context = LocalContext.current

    val pontosFiltrados = remember(pontos, searchText, selectedCategoria) {
        pontos.filter { ponto ->
            (selectedCategoria == CategoriaPonto.TODOS || ponto.categoria == selectedCategoria) &&
                    (searchText.isBlank() ||
                            ponto.nome?.contains(searchText, true) == true ||
                            ponto.texto?.contains(searchText, true) == true ||
                            ponto.end?.contains(searchText, true) == true)
        }
    }

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Scaffold(
            topBar = {
                HeaderSection(
                    searchText = searchText,
                    onSearchTextChange = { searchText = it },
                    selectedCategoria = selectedCategoria,
                    onCategoriaSelected = { selectedCategoria = it },
                    onMapClick = { mapState = MapState.Visible(pontosFiltrados) },
                    onShareClick = { shareAllContent(context, pontosFiltrados, localizationViewModel) },
                    onDismiss = onDismiss,
                    localizationViewModel = localizationViewModel
                )
            }
        ) { paddingValues ->
            Column(modifier = Modifier.fillMaxSize().padding(paddingValues)) {
                when {
                    isLoading -> Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
                    pontosFiltrados.isEmpty() -> Box(Modifier.fillMaxSize().padding(32.dp), Alignment.Center) {
                        EmptyStateView(
                            icon = Icons.Default.Map,
                            message = if (searchText.isBlank()) localizationViewModel.getString("no_tourist_spots_available")
                            else localizationViewModel.getString("no_results_found_for", searchText)
                        )
                    }
                    else -> {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            item {
                                Text(
                                    text = localizationViewModel.getString("points_found", pontosFiltrados.size),
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            items(pontosFiltrados, key = { it.id }) { ponto ->
                                PontoTuristicoCard(
                                    ponto = ponto,
                                    onClick = { selectedPonto = ponto },
                                    localizationViewModel = localizationViewModel
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    if (mapState is MapState.Visible) {
        val visibleState = mapState as MapState.Visible
        MapaPontosView(
            pontos = visibleState.pontos,
            pontoFocado = visibleState.pontoFocado,
            onDismiss = { mapState = MapState.Hidden },
            localizationViewModel = localizationViewModel
        )
    }

    selectedPonto?.let { ponto ->
        PontoTuristicoDetailView(
            ponto = ponto,
            onDismiss = { selectedPonto = null },
            onShowOnMap = { pontoAMostrar ->
                selectedPonto = null
                mapState = MapState.Visible(listOf(pontoAMostrar), pontoFocado = pontoAMostrar)
            },
            localizationViewModel = localizationViewModel,
            context = context
        )
    }
}

@Composable
private fun HeaderSection(
    searchText: String, onSearchTextChange: (String) -> Unit, selectedCategoria: CategoriaPonto,
    onCategoriaSelected: (CategoriaPonto) -> Unit, onMapClick: () -> Unit, onShareClick: () -> Unit,
    onDismiss: () -> Unit, localizationViewModel: LocalizationViewModel
) {
    Surface(shadowElevation = 4.dp) {
        Column(modifier = Modifier.statusBarsPadding().padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(localizationViewModel.getString("tourist_spots"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                IconButton(onClick = onMapClick) { Icon(Icons.Default.Map, localizationViewModel.getString("view_on_map")) }
                IconButton(onClick = onShareClick) { Icon(Icons.Default.Share, localizationViewModel.getString("share_list")) }
                IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, localizationViewModel.getString("close")) }
            }
            OutlinedTextField(
                value = searchText, onValueChange = onSearchTextChange, modifier = Modifier.fillMaxWidth(),
                placeholder = { Text(localizationViewModel.getString("search_tourist_spots")) },
                leadingIcon = { Icon(Icons.Default.Search, null) },
                trailingIcon = { if (searchText.isNotEmpty()) IconButton(onClick = { onSearchTextChange("") }) { Icon(Icons.Default.Clear, null) } },
                singleLine = true, shape = RoundedCornerShape(12.dp)
            )
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(CategoriaPonto.values()) { categoria ->
                    CategoryFilterChip(categoria, selectedCategoria == categoria, { onCategoriaSelected(categoria) }, localizationViewModel)
                }
            }
        }
    }
}

@Composable
private fun CategoryFilterChip(
    categoria: CategoriaPonto, isSelected: Boolean, onClick: () -> Unit, localizationViewModel: LocalizationViewModel
) {
    val categoryColor = categoria.getColor()
    FilterChip(
        selected = isSelected,
        onClick = onClick,
        label = { Text(categoria.getDisplayName(localizationViewModel), style = MaterialTheme.typography.labelMedium) },
        leadingIcon = { Icon(categoria.getIcon(), null, modifier = Modifier.size(16.dp)) },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = categoryColor.copy(alpha = 0.2f),
            selectedLabelColor = categoryColor,
            selectedLeadingIconColor = categoryColor
        )
    )
}

@Composable
private fun PontoTuristicoCard(
    ponto: PontoTuristico, onClick: () -> Unit, localizationViewModel: LocalizationViewModel
) {
    Card(onClick = onClick, elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Surface(shape = RoundedCornerShape(8.dp), color = ponto.categoria.getColor().copy(alpha = 0.2f), modifier = Modifier.size(40.dp)) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(ponto.categoria.getIcon(), null, tint = ponto.categoria.getColor(), modifier = Modifier.size(24.dp))
                    }
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(ponto.nome.orEmpty(), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    ponto.end?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                }
                Icon(Icons.Default.ChevronRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun PontoTuristicoDetailView(
    ponto: PontoTuristico,
    onDismiss: () -> Unit,
    onShowOnMap: (PontoTuristico) -> Unit,
    localizationViewModel: LocalizationViewModel,
    context: Context
) {
    fun Context.findActivity(): Activity? {
        var currentContext = this
        while (currentContext is ContextWrapper) {
            if (currentContext is Activity) {
                return currentContext
            }
            currentContext = currentContext.baseContext
        }
        return null
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)) {
        Column(modifier = Modifier.verticalScroll(rememberScrollState()).navigationBarsPadding().padding(bottom = 16.dp)) {
            Box(
                modifier = Modifier.fillMaxWidth().height(200.dp).background(Brush.verticalGradient(listOf(ponto.categoria.getColor(), ponto.categoria.getColor().copy(alpha = 0.7f)))),
                contentAlignment = Alignment.Center
            ) {
                Icon(ponto.categoria.getIcon(), null, modifier = Modifier.size(80.dp), tint = Color.White.copy(alpha = 0.5f))
            }
            Column(modifier = Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text(ponto.nome.orEmpty(), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    ActionButton(
                        Icons.Default.Map,
                        localizationViewModel.getString("map") ?: "Map",
                        MaterialTheme.colorScheme.primary,
                        ponto.coordenadas != null,
                        { onShowOnMap(ponto) },
                        Modifier.weight(1f)
                    )
                    ActionButton(
                        Icons.Default.Language,
                        localizationViewModel.getString("website") ?: "Website",
                        Color(0xFFFF9800),
                        !ponto.website.isNullOrBlank(),
                        {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(ponto.website))
                            val activity = context.findActivity()
                            if (activity != null) {
                                activity.startActivity(intent)
                            } else {
                                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                context.startActivity(intent)
                            }
                        },
                        Modifier.weight(1f)
                    )
                    ActionButton(
                        Icons.Default.Share,
                        localizationViewModel.getString("share") ?: "Share",
                        Color(0xFF9C27B0),
                        true,
                        { sharePonto(ponto, context, localizationViewModel) },
                        Modifier.weight(1f)
                    )
                }
                Divider()
                ponto.texto?.let { InfoSection(Icons.Default.Info, localizationViewModel.getString("description"), it, MaterialTheme.colorScheme.secondary) }
                ponto.coordenadas?.let {
                    Card(onClick = { onShowOnMap(ponto) }, modifier = Modifier.fillMaxWidth().height(150.dp)) {
                        Box(Modifier.fillMaxSize(), Alignment.Center) { Text("Ver no mapa") }
                    }
                }
            }
        }
    }
}

@Composable
private fun ActionButton(icon: ImageVector, title: String, color: Color, enabled: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Card(
        onClick = { if (enabled) onClick() },
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (enabled) color else MaterialTheme.colorScheme.surfaceVariant,
            contentColor = if (enabled) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (enabled) 2.dp else 0.dp)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(icon, null, modifier = Modifier.size(20.dp))
            Text(title, style = MaterialTheme.typography.labelSmall)
        }
    }
}

@Composable
private fun InfoSection(icon: ImageVector, title: String, content: String, color: Color) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(icon, null, tint = color, modifier = Modifier.size(20.dp))
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        }
        Surface(shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)) {
            Text(content, modifier = Modifier.fillMaxWidth().padding(16.dp), style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
private fun MapaPontosView(
    pontos: List<PontoTuristico>, pontoFocado: PontoTuristico?, onDismiss: () -> Unit, localizationViewModel: LocalizationViewModel
) {
    val pontosComCoordenadas = remember(pontos) { pontos.filter { it.coordenadas != null } }
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            pontoFocado?.coordenadas ?: LatLng(-22.9068, -43.1729),
            if (pontoFocado != null) 15f else 11f
        )
    }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(pontoFocado?.nome ?: localizationViewModel.getString("all_points"), fontWeight = FontWeight.Bold) },
                    navigationIcon = { IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, null) } }
                )
            }
        ) { padding ->
            GoogleMap(modifier = Modifier.fillMaxSize().padding(padding), cameraPositionState = cameraPositionState) {
                pontosComCoordenadas.forEach { ponto ->
                    ponto.coordenadas?.let {
                        Marker(
                            state = MarkerState(position = it),
                            title = ponto.nome,
                            snippet = ponto.categoria.getDisplayName(localizationViewModel)
                        )
                    }
                }
            }
        }
    }
}

private fun shareAllContent(context: Context, pontos: List<PontoTuristico>, localizationViewModel: LocalizationViewModel) {
    fun Context.findActivity(): Activity? {
        var currentContext = this
        while (currentContext is ContextWrapper) {
            if (currentContext is Activity) {
                return currentContext
            }
            currentContext = currentContext.baseContext
        }
        return null
    }

    val intro = localizationViewModel.getString("tourist_spots_rio")
    val texto = pontos.joinToString("\n\n---\n\n") { ponto ->
        buildString {
            appendLine(ponto.nome ?: localizationViewModel.getString("no_name"))
            ponto.end?.let { appendLine(it) }
            ponto.texto?.let { appendLine("\n$it") }
        }
    }
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, "$intro:\n\n$texto")
    }

    val chooserIntent = Intent.createChooser(intent, localizationViewModel.getString("share"))
    val activity = context.findActivity()
    if (activity != null) {
        activity.startActivity(chooserIntent)
    } else {
        chooserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(chooserIntent)
    }
}

private fun sharePonto(ponto: PontoTuristico, context: Context, localizationViewModel: LocalizationViewModel) {
    fun Context.findActivity(): Activity? {
        var currentContext = this
        while (currentContext is ContextWrapper) {
            if (currentContext is Activity) {
                return currentContext
            }
            currentContext = currentContext.baseContext
        }
        return null
    }

    val shareText = buildString {
        appendLine(ponto.nome ?: localizationViewModel.getString("tourist_spot"))
        ponto.end?.let { appendLine("\n${localizationViewModel.getString("address")}: $it") }
        ponto.texto?.let { appendLine("\n$it") }
        ponto.coordenadas?.let {
            appendLine("\nMaps: https://www.google.com/maps/search/?api=1&query=${it.latitude},${it.longitude}")
        }
    }
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, shareText)
    }

    val chooserIntent = Intent.createChooser(intent, localizationViewModel.getString("share_spot"))
    val activity = context.findActivity()
    if (activity != null) {
        activity.startActivity(chooserIntent)
    } else {
        chooserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(chooserIntent)
    }
}

private fun CategoriaPonto.getIcon(): ImageVector = when (this) {
    CategoriaPonto.TODOS -> Icons.Default.GridView
    CategoriaPonto.PATRIMONIO -> Icons.Default.AccountBalance
    CategoriaPonto.PRAIA -> Icons.Default.BeachAccess
    CategoriaPonto.PARQUE -> Icons.Default.Park
    CategoriaPonto.MUSEU -> Icons.Default.Museum
    CategoriaPonto.CULTURA -> Icons.Default.TheaterComedy
    CategoriaPonto.ESPORTE -> Icons.Default.SportsBaseball
    CategoriaPonto.ARTE -> Icons.Default.Palette
    CategoriaPonto.BIBLIOTECA -> Icons.Default.MenuBook
    CategoriaPonto.MIRANTE -> Icons.Default.Landscape
    CategoriaPonto.OUTRO -> Icons.Default.Star
}

@Composable
private fun CategoriaPonto.getColor(): Color = when (this) {
    CategoriaPonto.TODOS -> MaterialTheme.colorScheme.onSurfaceVariant
    CategoriaPonto.PATRIMONIO -> Color(0xFF795548)
    CategoriaPonto.PRAIA -> MaterialTheme.colorScheme.primary
    CategoriaPonto.PARQUE -> Color(0xFF4CAF50)
    CategoriaPonto.MUSEU -> Color(0xFF9C27B0)  // Purple color for MUSEU
    CategoriaPonto.CULTURA -> MaterialTheme.colorScheme.error
    CategoriaPonto.ESPORTE -> Color(0xFF3F51B5)
    CategoriaPonto.ARTE -> MaterialTheme.colorScheme.tertiary  // Using tertiary color for ARTE
    CategoriaPonto.BIBLIOTECA -> Color(0xFF795548)
    CategoriaPonto.MIRANTE -> Color(0xFF009688)
    CategoriaPonto.OUTRO -> Color.Gray
}

private fun CategoriaPonto.getDisplayName(localization: LocalizationViewModel): String = when (this) {
    CategoriaPonto.TODOS -> localization.getString("category_all")
    CategoriaPonto.PATRIMONIO -> localization.getString("category_heritage")
    CategoriaPonto.PRAIA -> localization.getString("category_beach")
    CategoriaPonto.PARQUE -> localization.getString("category_park")
    CategoriaPonto.MUSEU -> localization.getString("category_museum")
    CategoriaPonto.CULTURA -> localization.getString("category_culture")
    CategoriaPonto.ESPORTE -> localization.getString("category_sports")
    CategoriaPonto.ARTE -> localization.getString("category_art")
    CategoriaPonto.BIBLIOTECA -> localization.getString("category_library")
    CategoriaPonto.MIRANTE -> localization.getString("category_viewpoint")
    CategoriaPonto.OUTRO -> localization.getString("category_other")
}

private fun Context.findActivity(): Activity? {
    var currentContext = this
    while (currentContext is ContextWrapper) {
        if (currentContext is Activity) {
            return currentContext
        }
        currentContext = currentContext.baseContext
    }
    return null
}