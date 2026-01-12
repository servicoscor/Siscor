@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
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
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.clustering.ClusterItem
import com.google.maps.android.compose.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import java.util.Locale
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

private const val CAMERA_STREAM_BASE_URL = "https://dev.tixxi.rio/outvideo3/"
private const val CAMERA_STREAM_KEY = "G5325"
private const val CAMERA_VISIBILITY_RADIUS_KM = 2.0

fun buildCameraStreamUrl(code: String?): String? {
    return code?.let { "${CAMERA_STREAM_BASE_URL}?CODE=$it&KEY=$CAMERA_STREAM_KEY" }
}

private fun distanceKm(from: LatLng, to: LatLng): Double {
    val earthRadiusKm = 6371.0
    val dLat = Math.toRadians(to.latitude - from.latitude)
    val dLon = Math.toRadians(to.longitude - from.longitude)
    val lat1 = Math.toRadians(from.latitude)
    val lat2 = Math.toRadians(to.latitude)
    val a = sin(dLat / 2) * sin(dLat / 2) +
            sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
    val c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earthRadiusKm * c
}


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

data class CameraClusterItem(
    val camera: Camera
) : ClusterItem {
    override fun getPosition(): LatLng = camera.coordinate!!
    override fun getTitle(): String? = camera.nome
    override fun getSnippet(): String? = null
    override fun getZIndex(): Float? = null
}

// ✅ FUNÇÃO PRINCIPAL QUE O MAINSCREEN USA
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

    val validCameras = remember(cameras) {
        cameras.filter { camera ->
            camera.coordinate != null &&
                    camera.coordinate!!.latitude != 0.0 &&
                    camera.coordinate!!.longitude != 0.0
        }
    }
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
            13f
        )
    }
    var mapCenter by remember { mutableStateOf(cameraPositionState.position.target) }
    val visibleCameras by remember(validCameras, mapCenter) {
        derivedStateOf {
            validCameras.filter { camera ->
                val coordinate = camera.coordinate!!
                distanceKm(mapCenter, coordinate) <= CAMERA_VISIBILITY_RADIUS_KM
            }
        }
    }

    LaunchedEffect(cameraPositionState) {
        snapshotFlow { cameraPositionState.isMoving }
            .distinctUntilChanged()
            .collectLatest { isMoving ->
                if (!isMoving) {
                    mapCenter = cameraPositionState.position.target
                }
            }
    }
    val contentColor = MaterialTheme.colorScheme.onPrimary

    if (showCameraSelectionDialog) {
        CameraSelectionDialog(
            cameras = validCameras,
            favoriteCameraIds = favoriteCameraIds,
            onCameraSelected = { camera ->
                onToggleFavorite(camera.id)
                showCameraSelectionDialog = false
            },
            onDismiss = { showCameraSelectionDialog = false },
            localizationViewModel = localizationViewModel
        )
    }

    Card(
        onClick = { onExpand() },
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
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.08f),
                            Color.White.copy(alpha = 0.04f)
                        )
                    )
                )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Default.Videocam,
                        null,
                        tint = contentColor,
                        modifier = Modifier.size(24.dp)
                    )
                    Text(
                        text = localizationViewModel.getString("traffic_cameras"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = contentColor
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    if (cameras.isNotEmpty()) {
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = contentColor.copy(alpha = 0.2f)
                        ) {
                            Text(
                                "${cameras.size}",
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelLarge,
                                color = contentColor,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(110.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    FavoriteCameraCard(
                        modifier = Modifier.weight(1f),
                        camera = favoriteCameraIds.getOrNull(0)?.let { id ->
                            cameras.find { it.id == id || it.apiId == id }
                        },
                        slotNumber = 1,
                        onCardClick = { camera ->
                            if (camera != null) {
                                cameraForModal = camera
                            } else {
                                showCameraSelectionDialog = true
                            }
                        },
                        onRemoveClick = { cam ->
                            onToggleFavorite(cam.id)
                        }
                    )

                    FavoriteCameraCard(
                        modifier = Modifier.weight(1f),
                        camera = favoriteCameraIds.getOrNull(1)?.let { id ->
                            cameras.find { it.id == id || it.apiId == id }
                        },
                        slotNumber = 2,
                        onCardClick = { camera ->
                            if (camera != null) {
                                cameraForModal = camera
                            } else {
                                showCameraSelectionDialog = true
                            }
                        },
                        onRemoveClick = { cam ->
                            onToggleFavorite(cam.id)
                        }
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(350.dp)
                        .clip(RoundedCornerShape(12.dp))
                ) {
                    Box(modifier = Modifier.fillMaxSize()) {
                        when {
                            cameras.isEmpty() -> {
                                Box(
                                    modifier = Modifier.fillMaxSize(),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        CircularProgressIndicator(
                                            color = contentColor,
                                            modifier = Modifier.size(32.dp)
                                        )
                                        Text(
                                            text = "Carregando câmeras...",
                                            color = contentColor.copy(alpha = 0.8f),
                                            style = MaterialTheme.typography.bodyMedium
                                        )
                                    }
                                }
                            }

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
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .clip(RoundedCornerShape(12.dp)),
                                    cameraPositionState = cameraPositionState,
                                    properties = MapProperties(
                                        isMyLocationEnabled = isLocationPermissionGranted,
                                        isTrafficEnabled = false,
                                        isIndoorEnabled = false
                                    ),
                                    uiSettings = MapUiSettings(
                                        scrollGesturesEnabled = true,
                                        zoomGesturesEnabled = true,
                                        zoomControlsEnabled = false,
                                        myLocationButtonEnabled = false,
                                        mapToolbarEnabled = false,
                                        tiltGesturesEnabled = true,
                                        rotationGesturesEnabled = true,
                                        compassEnabled = true
                                    ),
                                    onMapLoaded = {
                                        isMapReady = true
                                        mapCenter = cameraPositionState.position.target
                                        if (isLocationPermissionGranted) {
                                            localizationViewModel.startLocationUpdates()
                                        }
                                    }
                                ) {
                                    visibleCameras.forEach { camera ->
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
                                        text = "${visibleCameras.size} câmeras",
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
                                text = camera.nome ?: "Câmera $slotNumber",
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
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .fillMaxHeight(0.7f),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Selecionar Câmera",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Fechar")
                    }
                }

                HorizontalDivider()

                if (cameras.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Nenhuma câmera disponível",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(cameras, key = { it.id }) { camera ->
                            val isFavorite = favoriteCameraIds.contains(camera.id) ||
                                    favoriteCameraIds.contains(camera.apiId)

                            Card(
                                onClick = {
                                    if (!isFavorite) {
                                        onCameraSelected(camera)
                                    }
                                },
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(
                                    containerColor = if (isFavorite)
                                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                                    else
                                        MaterialTheme.colorScheme.surfaceVariant
                                )
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = if (isFavorite) Icons.Default.Star else Icons.Default.Videocam,
                                        contentDescription = null,
                                        tint = if (isFavorite) Color(0xFFFFC107) else MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(24.dp)
                                    )

                                    Spacer(Modifier.width(12.dp))

                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = camera.nome ?: "Câmera sem nome",
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.Medium,
                                            maxLines = 1,
                                            overflow = TextOverflow.Ellipsis
                                        )
                                        if (camera.apiId != null) {
                                            Text(
                                                text = "ID: ${camera.apiId}",
                                                style = MaterialTheme.typography.labelSmall,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                    }

                                    if (isFavorite) {
                                        Text(
                                            text = "Favorita",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    } else {
                                        Icon(
                                            imageVector = Icons.Default.Add,
                                            contentDescription = "Adicionar",
                                            tint = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                }
                            }
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
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Error,
                contentDescription = null,
                tint = contentColor,
                modifier = Modifier.size(48.dp)
            )
            Text(
                text = localizationViewModel.getString("map_error"),
                color = contentColor,
                style = MaterialTheme.typography.bodyMedium
            )
            OutlinedButton(onClick = onRetry) {
                Text(localizationViewModel.getString("retry"))
            }
        }
    }
}

@Composable
private fun EmptyCamerasState(
    localizationViewModel: LocalizationViewModel,
    contentColor: Color
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Default.VideocamOff,
                contentDescription = null,
                tint = contentColor.copy(alpha = 0.6f),
                modifier = Modifier.size(48.dp)
            )
            Text(
                text = localizationViewModel.getString("no_cameras_available"),
                color = contentColor.copy(alpha = 0.8f),
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

// ✅ FUNÇÃO QUE O MAINSCREEN USA PARA TELA CHEIA
@Composable
fun CamerasMapFullScreen(
    cameras: List<Camera>,
    isLocationPermissionGranted: Boolean,
    onDismiss: () -> Unit,
    onCameraSelected: (Camera) -> Unit,
    localizationViewModel: LocalizationViewModel,
    favoriteCameraIds: List<String>,
    onToggleFavorite: (String) -> Unit
) {
    var selectedCamera by remember { mutableStateOf<Camera?>(null) }
    var isMapReady by remember { mutableStateOf(false) }
    var cameraForModal by remember { mutableStateOf<Camera?>(null) }

    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()

    val validCameras = remember(cameras) {
        cameras.filter { camera ->
            camera.coordinate != null &&
                    camera.coordinate!!.latitude != 0.0 &&
                    camera.coordinate!!.longitude != 0.0
        }
    }

    val initialPosition = remember {
        LatLng(-22.908333, -43.196388)
    }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(initialPosition, 13f)
    }
    var mapCenter by remember { mutableStateOf(cameraPositionState.position.target) }
    val visibleCameras by remember(validCameras, mapCenter) {
        derivedStateOf {
            validCameras.filter { camera ->
                val coordinate = camera.coordinate!!
                distanceKm(mapCenter, coordinate) <= CAMERA_VISIBILITY_RADIUS_KM
            }
        }
    }

    LaunchedEffect(cameraPositionState) {
        snapshotFlow { cameraPositionState.isMoving }
            .distinctUntilChanged()
            .collectLatest { isMoving ->
                if (!isMoving) {
                    mapCenter = cameraPositionState.position.target
                }
            }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = MapProperties(isMyLocationEnabled = isLocationPermissionGranted),
            uiSettings = MapUiSettings(
                zoomControlsEnabled = true,
                myLocationButtonEnabled = true,
                mapToolbarEnabled = true
            ),
            onMapLoaded = {
                isMapReady = true
                mapCenter = cameraPositionState.position.target
            }
        ) {
            visibleCameras.forEach { camera ->
                val coordinate = camera.coordinate
                if (coordinate != null) {
                    val isFavorite = favoriteCameraIds.contains(camera.id) ||
                            favoriteCameraIds.contains(camera.apiId)

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
                text = "${visibleCameras.size} câmeras no mapa",
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

// ✅ FUNÇÃO QUE O MAINSCREEN USA PARA BOTTOM SHEET
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
                    camera.nome ?: "Câmera",
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
 * 🔥 CÂMERA MUITO MAIOR - Scale 0.50!
 * Substitui a função CameraPlayerFullscreenModal inteira por este código
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
        buildCameraStreamUrl(camera.apiId ?: camera.id)
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
            // CÂMERA
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
                                setInitialScale(30)  // ✅ FIXO! Não mexe!
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
                            scaleX = 2.3f,         // ainda mais zoom para preencher
                            scaleY = 2.3f,
                            clip = false,
                            translationX = -1375f, // volta mais um pouco para a direita
                            translationY = 220f    // ajuste fino vertical
                        )
                )
            }

            // HEADER COM NOME + X + ESTRELA
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
                        // BOTÃO X
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

                        // NOME DA CÂMERA
                        Text(
                            text = camera.nome ?: "Câmera",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .weight(1f)
                                .padding(horizontal = 8.dp),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )

                        // BOTÃO ESTRELA
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

            // LOADING
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


// ✅ SEALED CLASS QUE PRECISA ESTAR NO ARQUIVO
sealed class CameraWebViewState {
    object Loading : CameraWebViewState()
    object Success : CameraWebViewState()
    data class Error(val message: String) : CameraWebViewState()
}

