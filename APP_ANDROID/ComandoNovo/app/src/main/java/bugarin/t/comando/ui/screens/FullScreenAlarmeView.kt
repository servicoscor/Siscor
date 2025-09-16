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
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.Sirene
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
fun FullScreenAlarmeView(
    sirenes: List<Sirene>,
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
    val scope = rememberCoroutineScope()

    // ✅ PERFORMANCE: Debounced map initialization
    var isMapReady by remember { mutableStateOf(false) }
    var hasLocationInitialized by remember { mutableStateOf(false) }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.9083, -43.1963), 12f)
    }

    var searchQuery by remember { mutableStateOf("") }
    var showBottomSheet by remember { mutableStateOf(false) }

    // ✅ PERFORMANCE: Cached marker icon
    val sireneMarkerIcon = remember {
        BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_ORANGE)
    }

    // ✅ PERFORMANCE: Cached filtered results
    val sirenesFiltradas = remember(searchQuery, sirenes) {
        if (searchQuery.isBlank()) {
            sirenes
        } else {
            sirenes.filter {
                it.nome?.contains(searchQuery, true) == true ||
                        it.loc?.contains(searchQuery, true) == true // ✅ FIXED: Usar 'local' ao invés de 'endereco'
            }
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
                android.util.Log.w("FullScreenAlarme", "Animation failed: ${e.message}")
            }
        }
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
                    android.util.Log.d("FullScreenAlarme", "Map loaded successfully")
                }
            ) {
                // ✅ PERFORMANCE: Marcadores otimizados
                sirenesFiltradas.forEach { sirene ->
                    sirene.coordinate?.let {
                        key(sirene.id) { // Evita recriação desnecessária
                            Marker(
                                state = MarkerState(it),
                                title = sirene.nome,
                                snippet = sirene.loc, // ✅ FIXED: Usar 'local'
                                icon = sireneMarkerIcon
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
            OptimizedAlarmeHeaderSection(
                searchQuery = searchQuery,
                onSearchQueryChange = { searchQuery = it },
                onBackClick = onBackClick,
                onListClick = { showBottomSheet = true },
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
                                            android.util.Log.w("FullScreenAlarme", "Location animation failed")
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
    if (showBottomSheet) {
        ModalBottomSheet(
            onDismissRequest = { showBottomSheet = false },
            windowInsets = WindowInsets(0, 0, 0, 0)
        ) {
            OptimizedSirenesBottomSheet(
                sirenes = sirenesFiltradas,
                localizationViewModel = localizationViewModel
            )
        }
    }
}

// ✅ PERFORMANCE: Header otimizado
@Composable
private fun OptimizedAlarmeHeaderSection(
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit,
    onBackClick: () -> Unit,
    onListClick: () -> Unit,
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
                IconButton(onClick = onBackClick) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = localizationViewModel.getString("back")
                    )
                }
                Text(
                    localizationViewModel.getString("alarm_sirens"),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = onListClick) {
                    Icon(
                        Icons.Default.List,
                        contentDescription = localizationViewModel.getString("list_view")
                    )
                }
            }

            OutlinedTextField(
                value = searchQuery,
                onValueChange = onSearchQueryChange,
                modifier = Modifier.fillMaxWidth(),
                placeholder = {
                    Text(localizationViewModel.getString("search_sirens"))
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

// ✅ PERFORMANCE: Bottom sheet otimizado
@Composable
private fun OptimizedSirenesBottomSheet(
    sirenes: List<Sirene>,
    localizationViewModel: LocalizationViewModel
) {
    Column(
        modifier = Modifier
            .navigationBarsPadding()
            .padding(24.dp)
    ) {
        Text(
            localizationViewModel.getString("alarm_sirens"),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (sirenes.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.VolumeOff,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        localizationViewModel.getString("no_sirens_found"),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.heightIn(max = 400.dp)
            ) {
                items(sirenes, key = { it.id }) { sirene ->
                    OptimizedSireneItem(sirene = sirene, localizationViewModel = localizationViewModel)
                }
            }
        }
    }
}

@Composable
private fun OptimizedSireneItem(
    sirene: Sirene,
    localizationViewModel: LocalizationViewModel
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(
                    Icons.Default.VolumeUp,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                Text(
                    sirene.nome ?: localizationViewModel.getString("unnamed_siren"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Text(
                        localizationViewModel.getString("active"),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            // ✅ FIXED: Usar 'local' ao invés de 'endereco' e adicionar verificação de tipo
            sirene.loc?.let { local: String ->
                Row(
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.LocationOn,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp).padding(top = 2.dp)
                    )
                    Text(
                        local,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}