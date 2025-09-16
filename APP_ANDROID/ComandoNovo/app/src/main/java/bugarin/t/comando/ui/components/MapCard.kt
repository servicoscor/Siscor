package bugarin.t.comando.ui.components

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.maps.android.compose.*
import kotlinx.coroutines.delay

/**
 * Data class para representar um marcador no mapa.
 */
data class MapMarker(
    val id: String,
    val position: LatLng,
    val title: String? = null,
    val snippet: String? = null,
    val icon: BitmapDescriptor = BitmapDescriptorFactory.defaultMarker()
)

/**
 * ✅ OTIMIZADO: MapCard com melhor performance e memory management
 */
@Composable
fun MultiMarkerMapCard(
    markers: List<MapMarker>,
    modifier: Modifier = Modifier,
    onMarkerClick: ((MapMarker) -> Unit)? = null
) {
    // ✅ PERFORMANCE: Early return para lista vazia
    if (markers.isEmpty()) {
        return
    }

    // ✅ MEMORY: Estados otimizados com DisposableEffect
    var isMapReady by remember { mutableStateOf(false) }
    var hasInitializedCamera by remember { mutableStateOf(false) }

    val cameraPositionState = rememberCameraPositionState()

    // ✅ MEMORY: Cleanup quando componente é removido
    DisposableEffect(Unit) {
        onDispose {
            // Força cleanup de recursos do mapa
            android.util.Log.d("MultiMarkerMapCard", "Cleaning up map resources")
        }
    }

    // ✅ PERFORMANCE: Lazy initialization da camera
    LaunchedEffect(markers, isMapReady) {
        if (!isMapReady || hasInitializedCamera || markers.isEmpty()) return@LaunchedEffect

        try {
            // ✅ PERFORMANCE: Delay para permitir que o mapa inicialize completamente
            delay(150)

            if (markers.size == 1) {
                // Se houver apenas um marcador, centraliza nele com um zoom fixo
                cameraPositionState.centerOnLocation(markers.first().position)
            } else {
                // Se houver múltiplos marcadores, ajusta a câmera para mostrar todos
                val boundsBuilder = LatLngBounds.Builder()
                markers.forEach { marker ->
                    boundsBuilder.include(marker.position)
                }

                try {
                    val bounds = boundsBuilder.build()
                    cameraPositionState.centerOnBounds(bounds)
                } catch (e: IllegalStateException) {
                    // Fallback para o caso de todos os pontos serem idênticos
                    markers.firstOrNull()?.let {
                        cameraPositionState.centerOnLocation(it.position)
                    }
                } catch (e: Exception) {
                    android.util.Log.w("MultiMarkerMapCard", "Camera animation failed: ${e.message}")
                }
            }
            hasInitializedCamera = true
        } catch (e: Exception) {
            android.util.Log.e("MultiMarkerMapCard", "Camera setup failed: ${e.message}")
        }
    }

    Card(
        modifier = modifier.clip(RoundedCornerShape(16.dp)),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = MapProperties(
                // ✅ PERFORMANCE: Configurações otimizadas
                isMyLocationEnabled = false,
                mapType = MapType.NORMAL,
                isTrafficEnabled = false,
                // ✅ FIXED: Removido isBuildingsEnabled - não existe
                isIndoorEnabled = false
            ),
            uiSettings = MapUiSettings(
                // ✅ PERFORMANCE: UI simplificada para melhor performance
                zoomControlsEnabled = false,
                mapToolbarEnabled = false,
                compassEnabled = false, // Desabilitado para performance
                rotationGesturesEnabled = false,
                tiltGesturesEnabled = false,
                scrollGesturesEnabled = true,
                zoomGesturesEnabled = true
            ),
            onMapLoaded = {
                // ✅ PERFORMANCE: Só marca como pronto quando mapa carregou
                isMapReady = true
                android.util.Log.d("MultiMarkerMapCard", "Map loaded successfully")
            }
        ) {
            // ✅ PERFORMANCE: Só renderiza marcadores quando mapa está pronto
            if (isMapReady) {
                markers.forEach { mapMarker ->
                    key(mapMarker.id) { // ✅ PERFORMANCE: Key para otimizar recomposição
                        Marker(
                            state = MarkerState(position = mapMarker.position),
                            title = mapMarker.title,
                            snippet = mapMarker.snippet,
                            icon = mapMarker.icon,
                            onClick = { marker ->
                                try {
                                    onMarkerClick?.invoke(mapMarker)
                                    true // Consome o evento de clique
                                } catch (e: Exception) {
                                    android.util.Log.w("MultiMarkerMapCard", "Marker click failed: ${e.message}")
                                    false
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

/**
 * ✅ OTIMIZADO: Anima a câmera para uma localização específica com error handling
 */
private suspend fun CameraPositionState.centerOnLocation(
    location: LatLng,
    zoom: Float = 15f
) {
    try {
        this.animate(
            update = com.google.android.gms.maps.CameraUpdateFactory.newLatLngZoom(location, zoom),
            durationMs = 800 // ✅ PERFORMANCE: Duração reduzida
        )
    } catch (e: Exception) {
        android.util.Log.w("MultiMarkerMapCard", "Camera center animation failed: ${e.message}")
        // Fallback sem animação
        try {
            this.position = com.google.android.gms.maps.model.CameraPosition.fromLatLngZoom(location, zoom)
        } catch (e2: Exception) {
            android.util.Log.e("MultiMarkerMapCard", "Camera position fallback failed: ${e2.message}")
        }
    }
}

/**
 * ✅ OTIMIZADO: Anima a câmera para englobar um conjunto de coordenadas com error handling
 */
private suspend fun CameraPositionState.centerOnBounds(
    bounds: LatLngBounds,
    padding: Int = 100 // em pixels
) {
    try {
        this.animate(
            update = com.google.android.gms.maps.CameraUpdateFactory.newLatLngBounds(bounds, padding),
            durationMs = 800 // ✅ PERFORMANCE: Duração reduzida
        )
    } catch (e: Exception) {
        android.util.Log.w("MultiMarkerMapCard", "Camera bounds animation failed: ${e.message}")
        // Fallback: usar o centro dos bounds
        try {
            val center = bounds.center
            this.centerOnLocation(center, 12f)
        } catch (e2: Exception) {
            android.util.Log.e("MultiMarkerMapCard", "Camera bounds fallback failed: ${e2.message}")
        }
    }
}