@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.NivelCalor
import bugarin.t.comando.data.PontoDeApoio
import bugarin.t.comando.data.Recomendacao
import bugarin.t.comando.ui.utils.rememberInteractiveMapProperties
import bugarin.t.comando.ui.utils.rememberInteractiveMapUiSettings
import bugarin.t.comando.ui.utils.rememberLocationPermissionState
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@Composable
fun PontosResfriamentoScreen(
    pontosUnidadesSaude: List<PontoDeApoio>,
    pontosResfriamento: List<PontoDeApoio>,
    nivelCalor: NivelCalor,
    recomendacoes: List<Recomendacao>,
    onBackClick: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ✅ PERFORMANCE: Status bar management otimizado
    val view = LocalView.current
    if (!view.isInEditMode) {
        val window = (view.context as Activity).window
        val originalStatusBarColor = remember { window.statusBarColor }
        val originalIsLight = remember {
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars
        }

        DisposableEffect(Unit) {
            window.statusBarColor = Color.Black.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
            onDispose {
                window.statusBarColor = originalStatusBarColor
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = originalIsLight
            }
        }
    }

    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()
    val permissionState = rememberLocationPermissionState()
    var showRecomendacoes by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    // ✅ PERFORMANCE: Debounced map initialization
    var isMapReady by remember { mutableStateOf(false) }
    var hasLocationInitialized by remember { mutableStateOf(false) }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.9083, -43.1963), 12f)
    }

    var searchQuery by remember { mutableStateOf("") }
    var showLegendDialog by remember { mutableStateOf(false) }

    // ✅ PERFORMANCE: Cached marker icons - usar ícones padrão otimizados
    val coolingMarkerIcon = remember {
        BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE)
    }
    val healthMarkerIcon = remember {
        BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)
    }

    // ✅ PERFORMANCE: Cached filtered results
    val (pontosResfriamentoFiltrados, pontosUnidadesSaudeFiltrados) = remember(
        searchQuery,
        pontosResfriamento,
        pontosUnidadesSaude
    ) {
        if (searchQuery.isBlank()) {
            Pair(pontosResfriamento, pontosUnidadesSaude)
        } else {
            Pair(
                pontosResfriamento.filter {
                    it.nome?.contains(searchQuery, true) == true ||
                            it.endereco?.contains(searchQuery, true) == true
                },
                pontosUnidadesSaude.filter {
                    it.nome?.contains(searchQuery, true) == true ||
                            it.endereco?.contains(searchQuery, true) == true
                }
            )
        }
    }

    // ✅ PERFORMANCE: Debounced location updates
    LaunchedEffect(userLocation) {
        if (!hasLocationInitialized && userLocation != null && isMapReady) {
            kotlinx.coroutines.delay(300) // Debounce
            try {
                cameraPositionState.animate(
                    CameraUpdateFactory.newLatLngZoom(
                        LatLng(userLocation!!.latitude, userLocation!!.longitude),
                        14f
                    )
                )
                hasLocationInitialized = true
            } catch (e: Exception) {
                android.util.Log.w("PontosResfriamento", "Animation failed: ${e.message}")
            }
        }
    }

    // Legend dialog
    if (showLegendDialog) {
        AlertDialog(
            onDismissRequest = { showLegendDialog = false },
            title = { Text(localizationViewModel.getString("legend")) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            Icons.Default.AcUnit,
                            contentDescription = null,
                            tint = Color(0xFF29B6F6)
                        )
                        Text(localizationViewModel.getString("cooling_points"))
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            Icons.Default.LocalHospital,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                        Text(localizationViewModel.getString("health_units"))
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showLegendDialog = false }) {
                    Text(localizationViewModel.getString("ok"))
                }
            }
        )
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // ✅ PERFORMANCE: Lazy loading do mapa
        LaunchedEffect(Unit) {
            kotlinx.coroutines.delay(200) // Permite UI se estabilizar
            isMapReady = true
            if (permissionState.hasPermission) {
                localizationViewModel.startLocationUpdates()
            }
        }

        if (isMapReady) {
            GoogleMap(
                modifier = Modifier.fillMaxSize(),
                cameraPositionState = cameraPositionState,
                properties = MapProperties(
                    isMyLocationEnabled = permissionState.hasPermission,
                    // ✅ FIXED: Removido isBuildingsEnabled - não existe
                    isTrafficEnabled = false,
                    isIndoorEnabled = false
                ),
                uiSettings = MapUiSettings(
                    // ✅ PERFORMANCE: UI otimizada
                    compassEnabled = false,
                    mapToolbarEnabled = false
                ),
                onMapLoaded = {
                    // ✅ PERFORMANCE: Callback após carregamento
                    android.util.Log.d("PontosResfriamento", "Map loaded successfully")
                }
            ) {
                // ✅ PERFORMANCE: Marcadores otimizados
                pontosResfriamentoFiltrados.forEach { ponto ->
                    ponto.coordinate?.let {
                        key(ponto.id) { // Evita recriação desnecessária
                            Marker(
                                state = MarkerState(it),
                                title = ponto.nome,
                                snippet = ponto.endereco,
                                icon = coolingMarkerIcon
                            )
                        }
                    }
                }

                pontosUnidadesSaudeFiltrados.forEach { ponto ->
                    ponto.coordinate?.let {
                        key(ponto.id) { // Evita recriação desnecessária
                            Marker(
                                state = MarkerState(it),
                                title = ponto.nome,
                                snippet = ponto.endereco,
                                icon = healthMarkerIcon
                            )
                        }
                    }
                }
            }
        } else {
            // ✅ PERFORMANCE: Loading state
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    CircularProgressIndicator()
                    Text(localizationViewModel.getString("loading_map"))
                }
            }
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
        ) {
            // Header otimizado
            OptimizedHeaderSection(
                searchQuery = searchQuery,
                onSearchQueryChange = { searchQuery = it },
                onBackClick = onBackClick,
                localizationViewModel = localizationViewModel
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Heat level card otimizado
            OptimizedHeatLevelCard(
                nivelCalor = nivelCalor,
                onRecommendationsClick = { showRecomendacoes = true },
                localizationViewModel = localizationViewModel
            )

            Spacer(modifier = Modifier.weight(1f))

            // Floating action buttons
            if (isMapReady) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.End
                ) {
                    SmallFloatingActionButton(
                        onClick = { showLegendDialog = true },
                        modifier = Modifier.padding(end = 8.dp),
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    ) {
                        Icon(Icons.Default.Info, contentDescription = null)
                    }

                    FloatingActionButton(
                        onClick = {
                            if (permissionState.hasPermission) {
                                userLocation?.let { location ->
                                    scope.launch {
                                        try {
                                            cameraPositionState.animate(
                                                CameraUpdateFactory.newLatLngZoom(
                                                    LatLng(location.latitude, location.longitude),
                                                    15f
                                                )
                                            )
                                        } catch (e: Exception) {
                                            android.util.Log.w("PontosResfriamento", "Location animation failed")
                                        }
                                    }
                                }
                            } else {
                                permissionState.launchPermissionRequest()
                            }
                        }
                    ) {
                        Icon(
                            if (permissionState.hasPermission)
                                Icons.Default.MyLocation
                            else
                                Icons.Default.LocationDisabled,
                            contentDescription = null
                        )
                    }
                }
            }
        }
    }

    // ✅ PERFORMANCE: ModalBottomSheet otimizado
    if (showRecomendacoes) {
        ModalBottomSheet(
            onDismissRequest = { showRecomendacoes = false },
            windowInsets = WindowInsets(0, 0, 0, 0)
        ) {
            OptimizedRecomendacoesBottomSheet(
                recomendacoes = recomendacoes,
                localizationViewModel = localizationViewModel
            )
        }
    }
}

// ✅ PERFORMANCE: Header otimizado
@Composable
private fun OptimizedHeaderSection(
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit,
    onBackClick: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
        shadowElevation = 4.dp
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    localizationViewModel.getString("cooling_points_health"),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = onBackClick) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = localizationViewModel.getString("close")
                    )
                }
            }

            OutlinedTextField(
                value = searchQuery,
                onValueChange = onSearchQueryChange,
                modifier = Modifier.fillMaxWidth(),
                placeholder = {
                    Text(localizationViewModel.getString("search_points"))
                },
                leadingIcon = {
                    Icon(Icons.Default.Search, contentDescription = null)
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { onSearchQueryChange("") }) {
                            Icon(Icons.Default.Clear, contentDescription = null)
                        }
                    }
                },
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )
        }
    }
}

// ✅ PERFORMANCE: Heat level card otimizado
@Composable
private fun OptimizedHeatLevelCard(
    nivelCalor: NivelCalor,
    onRecommendationsClick: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primary
        ),
        onClick = onRecommendationsClick
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Thermostat,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    localizationViewModel.getString("we_are_in"),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.9f)
                )
                Text(
                    nivelCalor.situacao?.replace("calor", "Calor") ?: "Calor 1",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimary
                )
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    localizationViewModel.getString("recommendations"),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimary
                )
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
        }
    }
}

// ✅ PERFORMANCE: Bottom sheet otimizado
@Composable
private fun OptimizedRecomendacoesBottomSheet(
    recomendacoes: List<Recomendacao>,
    localizationViewModel: LocalizationViewModel
) {
    Column(
        modifier = Modifier
            .navigationBarsPadding()
            .padding(24.dp)
    ) {
        Text(
            localizationViewModel.getString("heat_recommendations"),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(16.dp))
        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.heightIn(max = 400.dp)
        ) {
            items(recomendacoes, key = { it.id }) { recomendacao ->
                recomendacao.nome?.let {
                    OptimizedRecomendacaoItem(text = it)
                }
            }
        }
    }
}

@Composable
private fun OptimizedRecomendacaoItem(text: String) {
    Row(
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            Icons.Default.WbSunny,
            contentDescription = null,
            tint = Color(0xFFFF9800),
            modifier = Modifier
                .size(24.dp)
                .padding(top = 2.dp)
        )
        Text(
            text.replace("pulalinha", "\n"),
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f)
        )
    }
}