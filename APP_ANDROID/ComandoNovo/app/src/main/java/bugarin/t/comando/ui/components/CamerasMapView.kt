@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.OpenInFull
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.Camera
import bugarin.t.comando.viewmodel.LocalizationViewModel
import android.location.Location
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.clustering.ClusterItem
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapEffect
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.MarkerComposable
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import kotlinx.coroutines.delay
import java.util.Locale
import kotlin.math.pow
import kotlin.math.sqrt

// Componente de icone customizado para pins do mapa
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

data class CameraClusterItem(
    val camera: Camera
) : ClusterItem {
    override fun getPosition(): LatLng = camera.coordinate!!
    override fun getTitle(): String? = camera.nome
    override fun getSnippet(): String? = null
    override fun getZIndex(): Float? = null
}

// FUNCAO PRINCIPAL QUE O MAINSCREEN USA
@Composable
fun CamerasMapView(
    cameras: List<Camera>,
    isLocationPermissionGranted: Boolean,
    onExpand: () -> Unit,
    onCameraSelected: (Camera) -> Unit,
    localizationViewModel: LocalizationViewModel,
    favoriteCameraIds: List<String>,
    onToggleFavorite: (String) -> Unit,
    onFavoriteClick: (Camera) -> Unit,
    onSelectCameraForFavorite: (Camera) -> Unit
) {
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()

    var isMapReady by remember { mutableStateOf(false) }
    var hasInitialized by remember { mutableStateOf(false) }
    var shouldShowMap by remember { mutableStateOf(false) }
    var mapError by remember { mutableStateOf(false) }
    var showCameraSelectionDialog by remember { mutableStateOf(false) }
    var cameraForModal by remember { mutableStateOf<Camera?>(null) }

    // Raio usado para filtro dinâmico; recalculado conforme zoom

    val validCameras = remember(cameras) {
        cameras.filter { camera ->
            camera.coordinate != null &&
                camera.coordinate!!.latitude != 0.0 &&
                camera.coordinate!!.longitude != 0.0
        }
    }

    // ⚡ OTIMIZAÇÃO: Filtrar câmeras por bounds visíveis com debouncing
    var visibleCameras by remember { mutableStateOf(validCameras) }
    var lastBoundsUpdate by remember { mutableStateOf(0L) }
    val DEBOUNCE_DELAY = 500L // 500ms de debounce

    var mapCenter by remember { mutableStateOf<LatLng?>(null) }
    var visibleCameras by remember(validCameras) { mutableStateOf(validCameras) }

    DisposableEffect(Unit) {
        onDispose {
            kotlin.runCatching {
                if (isLocationPermissionGranted) {
                    localizationViewModel.stopLocationUpdates()
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        delay(200)
        shouldShowMap = true
    }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            LatLng(-22.908333, -43.196388),
            12f
        )
    }

    // Atualiza câmeras visíveis com base em um raio de 200m a partir do centro do mapa
    LaunchedEffect(mapCenter, validCameras) {
        val center = mapCenter
        visibleCameras = if (center != null) {
            validCameras.filter { camera ->
                camera.coordinate?.let { distanceMeters(center, it) <= 200f } ?: false
            }
        } else {
            validCameras
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
                                        if (coordinate != null) {
                                            val isFavorite = favoriteCameraIds.contains(camera.id) ||
                                                favoriteCameraIds.contains(camera.apiId)

                                            MarkerComposable(
                                                state = MarkerState(position = coordinate),
                                                onClick = {
                                                    cameraForModal = camera
                                                    true
                                                }
                                            ) {
                                                CameraMapPin(
                                                    size = 40.dp,
                                                    backgroundColor = Color.White,
                                                    iconColor = if (isFavorite)
                                                        Color(0xFFFFC107)
                                                    else
                                                        MaterialTheme.colorScheme.primary
                                                )
                                            }
                                        }
                                    }
                                }

                                IconButton(
                                    onClick = { onExpand() },
                                    modifier = Modifier
                                        .align(Alignment.TopEnd)
                                        .padding(8.dp)
                                        .background(
                                            MaterialTheme.colorScheme.surface.copy(alpha = 0.9f),
                                            CircleShape
                                        )
                                ) {
                                    Icon(
                                        Icons.Default.OpenInFull,
                                        localizationViewModel.getString("expand_map"),
                                        modifier = Modifier.size(20.dp)
                                    )
                                }

                                Surface(
                                    modifier = Modifier
                                        .align(Alignment.BottomStart)
                                        .padding(8.dp),
                                    shape = RoundedCornerShape(8.dp),
                                    color = Color.Black.copy(alpha = 0.7f)
                                ) {
                                    Text(
                                        text = "${visibleCameras.size} cameras",
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        cameraForModal?.let { camera ->
            CameraPlayerFullscreenModal(
                camera = camera,
                onDismiss = { cameraForModal = null },
                localizationViewModel = localizationViewModel,
                favoriteCameraIds = favoriteCameraIds,
                onToggleFavorite = onToggleFavorite
            )
        }
    }
}

@Composable
private fun FavoriteCameraCard(
    modifier: Modifier = Modifier,
    camera: Camera?,
    slotNumber: Int,
    onCardClick: (Camera?) -> Unit,
    onRemoveClick: (Camera) -> Unit
) {
    Card(
        onClick = { onCardClick(camera) },
        modifier = modifier.fillMaxHeight(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF0C1427)
        ),
        border = BorderStroke(
            1.2.dp,
            Brush.linearGradient(
                colors = listOf(
                    Color.White.copy(alpha = 0.35f),
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.45f)
                )
            )
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(12.dp))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) { onCardClick(camera) }
        ) {
            if (camera != null) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(8.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(
                            Brush.linearGradient(
                                colors = listOf(
                                    Color(0xFF13203C),
                                    Color(0xFF0B1122)
                                )
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .align(Alignment.TopStart),
                        horizontalAlignment = Alignment.Start
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = camera.nome ?: "Camera $slotNumber",
                                style = MaterialTheme.typography.labelLarge,
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.weight(1f),
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                            IconButton(onClick = { onRemoveClick(camera) }, modifier = Modifier.size(32.dp)) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = "Remover",
                                    tint = Color.White
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(6.dp))
                        Button(
                            onClick = { onCardClick(camera) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFF0D6EFD),
                                contentColor = Color.White
                            ),
                            shape = RoundedCornerShape(8.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                        ) {
                            Icon(
                                Icons.Default.Videocam,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                "Abrir",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            } else {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(12.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.Videocam,
                        contentDescription = null,
                        tint = Color.White.copy(alpha = 0.5f),
                        modifier = Modifier.size(36.dp)
                    )
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = "Favorito $slotNumber",
                        color = Color.White.copy(alpha = 0.6f),
                        style = MaterialTheme.typography.labelSmall
                    )
                    Spacer(Modifier.height(8.dp))
                    Button(
                        onClick = { onCardClick(null) },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF0D6EFD),
                            contentColor = Color.White
                        ),
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Adicionar",
                            tint = Color.White,
                            modifier = Modifier.size(14.dp)
                        )
                        Spacer(Modifier.width(4.dp))
                        Text(
                            text = "Adicionar",
                            style = MaterialTheme.typography.labelSmall,
                            fontSize = 11.sp
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CameraSelectionDialog(
    cameras: List<Camera>,
    favoriteCameraIds: List<String>,
    onCameraSelected: (Camera) -> Unit,
    onDismiss: () -> Unit,
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
                            selectedCamera = camera
                            true
                        }
                    ) {
                        CameraMapPin(
                            size = 40.dp,
                            backgroundColor = Color.White,
                            iconColor = if (isFavorite)
                                Color(0xFFFFC107)
                            else
                                MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }

        IconButton(
            onClick = onDismiss,
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(16.dp)
                .background(Color.Black.copy(alpha = 0.5f), CircleShape)
        ) {
            Icon(Icons.Default.Close, contentDescription = "Fechar", tint = Color.White)
        }

        Surface(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 16.dp),
            shape = RoundedCornerShape(20.dp),
            color = Color.Black.copy(alpha = 0.7f)
        ) {
            Text(
                text = "${visibleCameras.size} cameras no mapa",
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                style = MaterialTheme.typography.labelMedium,
                color = Color.White
            )
        }

        selectedCamera?.let { cam ->
            CameraDetailsSheet(
                camera = cam,
                onDismiss = { selectedCamera = null },
                onViewCamera = { target ->
                    cameraForModal = target
                    selectedCamera = null
                },
                localizationViewModel = localizationViewModel,
                onToggleFavorite = onToggleFavorite,
                favoriteCameraIds = favoriteCameraIds
            )
        }
    }

    cameraForModal?.let { camera ->
        CameraPlayerFullscreenModal(
            camera = camera,
            onDismiss = { cameraForModal = null },
            localizationViewModel = localizationViewModel,
            favoriteCameraIds = favoriteCameraIds,
            onToggleFavorite = onToggleFavorite
        )
    }
}

// FUNCAO QUE O MAINSCREEN USA PARA BOTTOM SHEET
@Composable
fun CameraDetailsSheet(
    camera: Camera,
    onDismiss: () -> Unit,
    onViewCamera: (Camera) -> Unit,
    localizationViewModel: LocalizationViewModel,
    onToggleFavorite: (String) -> Unit,
    favoriteCameraIds: List<String>
) {
    val isFavorite = remember(favoriteCameraIds, camera) {
        favoriteCameraIds.contains(camera.id) || favoriteCameraIds.contains(camera.apiId)
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .navigationBarsPadding()
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    camera.nome ?: "Camera",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = { onToggleFavorite(camera.id) }) {
                    Icon(
                        imageVector = if (isFavorite) Icons.Default.Star else Icons.Default.StarBorder,
                        contentDescription = if (isFavorite) "Remover dos favoritos" else "Adicionar aos favoritos",
                        tint = if (isFavorite) Color(0xFFFFC107) else MaterialTheme.colorScheme.onSurface
                    )
                }
            }

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

            InfoRow(
                Icons.Default.CheckCircle,
                localizationViewModel.getString("status"),
                localizationViewModel.getString("active"),
                MaterialTheme.colorScheme.tertiary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                    Text(localizationViewModel.getString("close"))
                }
                Button(
                    onClick = {
                        onViewCamera(camera)
                        onDismiss()
                    },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Visibility, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(localizationViewModel.getString("view_camera"))
                }
            }
        }
    }
}

@Composable
private fun InfoRow(
    icon: ImageVector,
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurface
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(20.dp)
        )
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                color = valueColor,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

/**
 * CAMERA MUITO MAIOR - Scale 0.50!
 * Substitui a funcao CameraPlayerFullscreenModal inteira por este codigo
 */
@Composable
private fun CameraPlayerFullscreenModal(
    camera: Camera,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel,
    favoriteCameraIds: List<String>,
    onToggleFavorite: (String) -> Unit
) {
    var webViewState by remember { mutableStateOf<CameraWebViewState>(CameraWebViewState.Loading) }
    var reloadTrigger by remember { mutableStateOf(0) }

    val cameraUrl = remember(camera.apiId, camera.id) {
        val targetId = camera.apiId ?: camera.id
        targetId?.let { "https://aplicativo.cocr.com.br/camera/$it" }
    }

    val isFavorite = remember(favoriteCameraIds, camera) {
        favoriteCameraIds.contains(camera.id) || favoriteCameraIds.contains(camera.apiId)
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
                .systemBarsPadding()
        ) {
            if (cameraUrl != null) {
                AndroidView(
                    factory = { context ->
                        WebView(context).apply {
                            settings.apply {
                                javaScriptEnabled = true
                                domStorageEnabled = true
                                mediaPlaybackRequiresUserGesture = false
                                loadWithOverviewMode = false
                                useWideViewPort = false
                                setInitialScale(30)
                                setSupportZoom(false)
                                builtInZoomControls = false
                                displayZoomControls = false
                            }

                            setBackgroundColor(android.graphics.Color.BLACK)
                            isVerticalScrollBarEnabled = false
                            isHorizontalScrollBarEnabled = false

                            webChromeClient = object : android.webkit.WebChromeClient() {
                                override fun onProgressChanged(view: WebView?, newProgress: Int) {
                                    if (newProgress > 50) {
                                        webViewState = CameraWebViewState.Success
                                    }
                                }
                            }

                            webViewClient = object : WebViewClient() {
                                override fun onPageFinished(view: WebView?, url: String?) {
                                    view?.evaluateJavascript(
                                        """
                                        (function() {
                                            document.body.style.margin = '0';
                                            document.body.style.padding = '0';
                                            document.body.style.overflow = 'hidden';
                                            document.body.style.background = '#000';
                                            
                                            var videos = document.querySelectorAll('video, iframe, img');
                                            videos.forEach(function(v) {
                                                v.style.width = '100vw';
                                                v.style.height = '100vh';
                                                v.style.objectFit = 'cover';
                                                v.style.position = 'fixed';
                                                v.style.top = '0';
                                                v.style.left = '0';
                                            });
                                        })();
                                        """.trimIndent(),
                                        null
                                    )
                                    webViewState = CameraWebViewState.Success
                                }

                                override fun onReceivedError(
                                    view: WebView?,
                                    errorCode: Int,
                                    description: String?,
                                    failingUrl: String?
                                ) {
                                    webViewState = CameraWebViewState.Error(description ?: "Erro")
                                }
                            }
                            loadUrl(cameraUrl)
                        }
                    },
                    update = { webView ->
                        if (reloadTrigger > 0) {
                            webView.reload()
                            reloadTrigger = 0
                        }
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer(
                            rotationZ = 90f,
                            scaleX = 2.3f,
                            scaleY = 2.3f,
                            clip = false,
                            translationX = -1375f,
                            translationY = 220f
                        )
                )
            }

            Surface(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .fillMaxWidth(),
                color = Color.Transparent
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Black.copy(alpha = 0.7f),
                                    Color.Black.copy(alpha = 0.3f),
                                    Color.Transparent
                                )
                            )
                        )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .statusBarsPadding()
                            .padding(8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(
                            onClick = onDismiss,
                            modifier = Modifier.size(48.dp)
                        ) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = "Fechar",
                                tint = Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }

                        Text(
                            text = camera.nome ?: "Camera",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .weight(1f)
                                .padding(horizontal = 8.dp),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )

                        IconButton(
                            onClick = { onToggleFavorite(camera.id) },
                            modifier = Modifier.size(48.dp)
                        ) {
                            Icon(
                                imageVector = if (isFavorite) Icons.Default.Star else Icons.Default.StarBorder,
                                contentDescription = if (isFavorite) "Remover dos favoritos" else "Adicionar aos favoritos",
                                tint = if (isFavorite) Color(0xFFFFC107) else Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }
                }
            }

            if (webViewState is CameraWebViewState.Loading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(48.dp)
                    )
                }
            }
        }
    }
}

sealed class CameraWebViewState {
    object Loading : CameraWebViewState()
    object Success : CameraWebViewState()
    data class Error(val message: String) : CameraWebViewState()
}

private fun distanceMeters(a: LatLng, b: LatLng): Float {
    val results = FloatArray(1)
    Location.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude, results)
    return results[0]
}
