@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.Camera
import bugarin.t.comando.ui.theme.BaseCard
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.clustering.ClusterItem
import com.google.maps.android.compose.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale

// Componente de ícone customizado para pins do mapa
@Composable
fun CameraMapPin(
    modifier: Modifier = Modifier,
    size: Dp = 40.dp,
    backgroundColor: Color = Color.White,
    iconColor: Color = Color(0xFF007AFF)
) {
    Box(
        modifier = modifier
            .size(size)
            .shadow(
                elevation = 8.dp,
                shape = CircleShape,
                ambientColor = Color.Black.copy(alpha = 0.2f),
                spotColor = Color.Black.copy(alpha = 0.2f)
            )
            .background(
                color = backgroundColor,
                shape = CircleShape
            ),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(size * 0.75f)
                .background(
                    color = iconColor,
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Videocam,
                contentDescription = "Camera",
                modifier = Modifier.size(size * 0.4f),
                tint = Color.White
            )
        }
    }
}

// Wrapper para fazer Camera funcionar com ClusterItem
data class CameraClusterItem(
    val camera: Camera
) : ClusterItem {
    override fun getPosition(): LatLng = camera.coordinate!!
    override fun getTitle(): String? = camera.nome
    override fun getSnippet(): String? = null
    override fun getZIndex(): Float? = null
}

@Composable
fun CamerasMapView(
    cameras: List<Camera>,
    isLocationPermissionGranted: Boolean,
    onExpand: () -> Unit,
    onCameraSelected: (Camera) -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()

    // Estados otimizados
    var isMapReady by remember { mutableStateOf(false) }
    var hasInitialized by remember { mutableStateOf(false) }
    var shouldShowMap by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf(false) }

    // Cached computed values com verificações mais rigorosas
    val validCameras = remember(cameras) {
        cameras.filter { camera ->
            camera.coordinate != null &&
                    camera.coordinate!!.latitude != 0.0 &&
                    camera.coordinate!!.longitude != 0.0
        }
    }

    // Cleanup mais robusto quando componente é removido
    DisposableEffect(Unit) {
        android.util.Log.d("CamerasMapView", "Initializing cameras map")
        onDispose {
            android.util.Log.d("CamerasMapView", "Cleaning up cameras map resources")
            kotlin.runCatching {
                if (isLocationPermissionGranted) {
                    localizationViewModel.stopLocationUpdates()
                }
                System.gc()
            }.onFailure { e ->
                android.util.Log.e("CamerasMapView", "Error during cleanup: ${e.message}")
            }
        }
    }

    // Lazy loading com delay
    LaunchedEffect(Unit) {
        delay(200)
        shouldShowMap = true
    }

    // Static camera position
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.908333, -43.196388), 12f)
    }

    // Debounced location updates com verificações null mais seguras
    LaunchedEffect(userLocation, isMapReady) {
        kotlin.runCatching {
            val location = userLocation
            if (!hasInitialized &&
                location != null &&
                isMapReady &&
                isLocationPermissionGranted &&
                location.latitude != 0.0 &&
                location.longitude != 0.0) {

                delay(300)
                val targetLocation = LatLng(location.latitude, location.longitude)

                if (cameraPositionState.isMoving.not()) {
                    cameraPositionState.animate(
                        CameraUpdateFactory.newLatLngZoom(targetLocation, 14f)
                    )
                    hasInitialized = true
                    android.util.Log.d("CamerasMapView", "Camera animated to user location")
                }
            }
        }.onFailure { e ->
            android.util.Log.e("CamerasMapView", "Location animation failed: ${e.message}")
        }
    }

    val contentColor = MaterialTheme.colorScheme.onPrimary

    BaseCard(
        onClick = {
            kotlin.runCatching {
                onExpand()
            }.onFailure { e ->
                android.util.Log.e("CamerasMapView", "Error expanding map: ${e.message}")
            }
        },
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
        gradient = cardGradient
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(Icons.Default.Videocam, null, tint = contentColor, modifier = Modifier.size(24.dp))
                Text(
                    localizationViewModel.getString("traffic_cameras"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = contentColor
                )
                Spacer(modifier = Modifier.weight(1f))
                if (validCameras.isNotEmpty()) {
                    Surface(shape = RoundedCornerShape(12.dp), color = contentColor.copy(alpha = 0.2f)) {
                        Text(
                            "${validCameras.size}",
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelLarge,
                            color = contentColor,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.Black.copy(alpha = 0.3f))
            ) {
                when {
                    validCameras.isEmpty() -> {
                        EmptyCamerasState(localizationViewModel, contentColor)
                    }
                    !shouldShowMap -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(
                                color = contentColor,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }
                    mapError -> {
                        ErrorMapState(
                            localizationViewModel = localizationViewModel,
                            contentColor = contentColor,
                            onRetry = {
                                mapError = false
                                shouldShowMap = false
                                shouldShowMap = true
                            }
                        )
                    }
                    else -> {
                        GoogleMap(
                            modifier = Modifier.fillMaxSize(),
                            cameraPositionState = cameraPositionState,
                            properties = MapProperties(
                                isMyLocationEnabled = isLocationPermissionGranted,
                                isTrafficEnabled = false,
                                isIndoorEnabled = false
                            ),
                            uiSettings = MapUiSettings(
                                scrollGesturesEnabled = false,
                                zoomGesturesEnabled = false,
                                myLocationButtonEnabled = false,
                                mapToolbarEnabled = false,
                                tiltGesturesEnabled = false,
                                rotationGesturesEnabled = false,
                                compassEnabled = false
                            ),
                            onMapLoaded = {
                                kotlin.runCatching {
                                    isMapReady = true
                                    android.util.Log.d("CamerasMapView", "Map loaded successfully")
                                    if (isLocationPermissionGranted) {
                                        localizationViewModel.startLocationUpdates()
                                    }
                                }.onFailure { e ->
                                    android.util.Log.e("CamerasMapView", "Error in onMapLoaded: ${e.message}")
                                    mapError = true
                                }
                            }
                        ) {
                            // Renderizar marcadores com verificações null mais seguras
                            if (isMapReady && validCameras.isNotEmpty()) {
                                validCameras.forEach { camera ->
                                    kotlin.runCatching {
                                        val coordinate = camera.coordinate
                                        if (coordinate != null &&
                                            coordinate.latitude != 0.0 &&
                                            coordinate.longitude != 0.0) {

                                            MarkerComposable(
                                                state = MarkerState(position = coordinate),
                                                onClick = {
                                                    kotlin.runCatching {
                                                        onCameraSelected(camera)
                                                        true
                                                    }.getOrElse { e ->
                                                        android.util.Log.e("CamerasMapView", "Error selecting camera: ${e.message}")
                                                        false
                                                    }
                                                }
                                            ) {
                                                CameraMapPin(
                                                    size = 40.dp,
                                                    backgroundColor = Color.White,
                                                    iconColor = MaterialTheme.colorScheme.primary
                                                )
                                            }
                                        }
                                    }.onFailure { e ->
                                        android.util.Log.w("CamerasMapView", "Error rendering marker: ${e.message}")
                                    }
                                }
                            }
                        }

                        IconButton(
                            onClick = {
                                kotlin.runCatching {
                                    onExpand()
                                }.onFailure { e ->
                                    android.util.Log.e("CamerasMapView", "Error expanding map: ${e.message}")
                                }
                            },
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(8.dp)
                                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f), CircleShape)
                        ) {
                            Icon(Icons.Default.OpenInFull, localizationViewModel.getString("expand_map"), modifier = Modifier.size(20.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ErrorMapState(
    localizationViewModel: LocalizationViewModel,
    contentColor: Color,
    onRetry: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(Icons.Default.Error, null, tint = contentColor.copy(alpha = 0.5f), modifier = Modifier.size(48.dp))
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "Erro ao carregar mapa",
            style = MaterialTheme.typography.bodyMedium,
            color = contentColor.copy(alpha = 0.7f)
        )
        Spacer(modifier = Modifier.height(8.dp))
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(
                containerColor = contentColor.copy(alpha = 0.2f)
            )
        ) {
            Text("Tentar novamente", color = contentColor)
        }
    }
}

@Composable
private fun EmptyCamerasState(localizationViewModel: LocalizationViewModel, contentColor: Color) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(Icons.Default.VideocamOff, null, tint = contentColor.copy(alpha = 0.5f), modifier = Modifier.size(48.dp))
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            localizationViewModel.getString("no_cameras_available"),
            style = MaterialTheme.typography.bodyMedium,
            color = contentColor.copy(alpha = 0.7f)
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CamerasMapFullScreen(
    cameras: List<Camera>,
    isLocationPermissionGranted: Boolean,
    onDismiss: () -> Unit,
    onCameraSelected: (Camera) -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var selectedCamera by remember { mutableStateOf<Camera?>(null) }
    var isMapReady by remember { mutableStateOf(false) }
    var shouldShowMap by remember { mutableStateOf(false) }

    // Cached valid cameras com verificações mais rigorosas
    val validCameras = remember(cameras) {
        cameras.filter { camera ->
            camera.coordinate != null &&
                    camera.coordinate!!.latitude != 0.0 &&
                    camera.coordinate!!.longitude != 0.0
        }
    }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.9068, -43.1729), 12f)
    }

    // Cleanup mais robusto para fullscreen
    DisposableEffect(Unit) {
        android.util.Log.d("CamerasMapFullScreen", "Initializing fullscreen map")
        onDispose {
            android.util.Log.d("CamerasMapFullScreen", "Cleaning up fullscreen map")
            kotlin.runCatching {
                if (isLocationPermissionGranted) {
                    localizationViewModel.stopLocationUpdates()
                }
                System.gc()
            }.onFailure { e ->
                android.util.Log.e("CamerasMapFullScreen", "Error during cleanup: ${e.message}")
            }
        }
    }

    // Lazy loading do fullscreen map
    LaunchedEffect(Unit) {
        delay(500)
        shouldShowMap = true
        if (isLocationPermissionGranted) {
            localizationViewModel.startLocationUpdates()
        }
    }

    Dialog(onDismissRequest = {
        kotlin.runCatching {
            onDismiss()
        }.onFailure { e ->
            android.util.Log.e("CamerasMapFullScreen", "Error dismissing: ${e.message}")
        }
    }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(localizationViewModel.getString("traffic_cameras"), fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = {
                            kotlin.runCatching {
                                onDismiss()
                            }.onFailure { e ->
                                android.util.Log.e("CamerasMapFullScreen", "Error dismissing: ${e.message}")
                            }
                        }) {
                            Icon(Icons.Default.Close, null)
                        }
                    }
                )
            }
        ) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding)) {

                if (!shouldShowMap) {
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
                } else {
                    GoogleMap(
                        modifier = Modifier.fillMaxSize(),
                        cameraPositionState = cameraPositionState,
                        properties = MapProperties(
                            isMyLocationEnabled = isLocationPermissionGranted,
                            isTrafficEnabled = false
                        ),
                        uiSettings = MapUiSettings(
                            myLocationButtonEnabled = false,
                            zoomControlsEnabled = true,
                            compassEnabled = false
                        ),
                        onMapLoaded = {
                            kotlin.runCatching {
                                isMapReady = true
                                android.util.Log.d("CamerasMapFullScreen", "Fullscreen map loaded")
                            }.onFailure { e ->
                                android.util.Log.e("CamerasMapFullScreen", "Error in onMapLoaded: ${e.message}")
                            }
                        }
                    ) {
                        // Renderizar marcadores com verificações null mais seguras
                        if (isMapReady && validCameras.isNotEmpty()) {
                            validCameras.forEach { camera ->
                                kotlin.runCatching {
                                    val coordinate = camera.coordinate
                                    if (coordinate != null &&
                                        coordinate.latitude != 0.0 &&
                                        coordinate.longitude != 0.0) {

                                        MarkerComposable(
                                            state = MarkerState(position = coordinate),
                                            onClick = {
                                                kotlin.runCatching {
                                                    selectedCamera = camera
                                                    true
                                                }.getOrElse { e ->
                                                    android.util.Log.e("CamerasMapFullScreen", "Error selecting camera: ${e.message}")
                                                    false
                                                }
                                            }
                                        ) {
                                            CameraMapPin(
                                                size = 48.dp,
                                                backgroundColor = Color.White,
                                                iconColor = MaterialTheme.colorScheme.primary
                                            )
                                        }
                                    }
                                }.onFailure { e ->
                                    android.util.Log.w("CamerasMapFullScreen", "Error rendering marker: ${e.message}")
                                }
                            }
                        }
                    }
                }

                if (isLocationPermissionGranted && isMapReady && shouldShowMap) {
                    FloatingActionButton(
                        onClick = {
                            kotlin.runCatching {
                                val location = userLocation
                                if (location != null &&
                                    location.latitude != 0.0 &&
                                    location.longitude != 0.0) {

                                    scope.launch {
                                        kotlin.runCatching {
                                            val targetLocation = LatLng(location.latitude, location.longitude)
                                            cameraPositionState.animate(
                                                CameraUpdateFactory.newLatLngZoom(targetLocation, 15f)
                                            )
                                        }.onFailure { e ->
                                            android.util.Log.e("CamerasMapFullScreen", "Location animation failed: ${e.message}")
                                        }
                                    }
                                }
                            }.onFailure { e ->
                                android.util.Log.e("CamerasMapFullScreen", "Error in location button: ${e.message}")
                            }
                        },
                        modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp)
                    ) { Icon(Icons.Default.MyLocation, null) }
                }

                selectedCamera?.let { camera ->
                    CameraDetailsSheet(
                        camera = camera,
                        onDismiss = { selectedCamera = null },
                        onViewCamera = {
                            kotlin.runCatching {
                                onDismiss()
                                onCameraSelected(camera)
                            }.onFailure { e ->
                                android.util.Log.e("CamerasMapFullScreen", "Error viewing camera: ${e.message}")
                            }
                        },
                        localizationViewModel = localizationViewModel
                    )
                }
            }
        }
    }
}

@Composable
private fun CameraDetailsSheet(
    camera: Camera,
    onDismiss: () -> Unit,
    onViewCamera: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier.navigationBarsPadding().padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(camera.nome.orEmpty(), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            HorizontalDivider()
            camera.coordinate?.let { coordinate ->
                if (coordinate.latitude != 0.0 && coordinate.longitude != 0.0) {
                    InfoRow(
                        Icons.Default.MyLocation,
                        localizationViewModel.getString("location"),
                        "${String.format(Locale.US, "%.4f", coordinate.latitude)}, ${String.format(Locale.US, "%.4f", coordinate.longitude)}"
                    )
                }
            }
            InfoRow(Icons.Default.CheckCircle, localizationViewModel.getString("status"), localizationViewModel.getString("active"), MaterialTheme.colorScheme.tertiary)
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                    Text(localizationViewModel.getString("close"))
                }
                Button(onClick = onViewCamera, modifier = Modifier.weight(1f)) {
                    Icon(Icons.Default.Visibility, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(localizationViewModel.getString("view_camera"))
                }
            }
        }
    }
}

@Composable
private fun InfoRow(icon: ImageVector, label: String, value: String, valueColor: Color = MaterialTheme.colorScheme.onSurface) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp).padding(top = 2.dp))
        Column {
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, style = MaterialTheme.typography.bodyLarge, color = valueColor, fontWeight = FontWeight.Medium)
        }
    }
}