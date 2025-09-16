package bugarin.t.comando.ui.components

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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.Sirene
import bugarin.t.comando.ui.theme.BaseCard
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.ui.utils.rememberCardMapProperties
import bugarin.t.comando.ui.utils.rememberCardMapUiSettings
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@Composable
fun SistemaAlarmeMapView(
    sirenes: List<Sirene>,
    onExpand: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ❌ REMOVIDO: A instanciação local do LocationManager foi removida para corrigir o vazamento de recursos.
    // val locationManager = remember { LocationManager(context) }

    var hasInitializedToUserLocation by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.908333, -43.196388), 12f)
    }

    // ✅ ATUALIZADO: A localização agora é consumida de forma segura a partir do ViewModel.
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()

    // ✅ ATUALIZADO: O ViewModel é comandado para iniciar as atualizações quando o componente é exibido.
    // A limpeza (stop) é garantida pelo ciclo de vida do ViewModel.
    LaunchedEffect(Unit) {
        localizationViewModel.startLocationUpdates()
    }

    // Anima a câmera para a localização do usuário uma única vez.
    LaunchedEffect(userLocation) {
        if (!hasInitializedToUserLocation && userLocation != null) {
            userLocation?.let { location ->
                scope.launch {
                    cameraPositionState.animate(
                        CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 13f)
                    )
                }
                hasInitializedToUserLocation = true
            }
        }
    }

    val mapProperties = rememberCardMapProperties()
    val mapUiSettings = rememberCardMapUiSettings()

    // ✅ TEMATIZAÇÃO: Cor do conteúdo baseada no tema para melhor adaptabilidade.
    val contentColor = MaterialTheme.colorScheme.onPrimary

    BaseCard(
        onClick = onExpand,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
        gradient = cardGradient
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(Icons.Default.NotificationsActive, null, tint = contentColor, modifier = Modifier.size(24.dp))
                Text(
                    text = localizationViewModel.getString("alarm_system"),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = contentColor
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            val sirenesAtivas = sirenes.count { isSireneMobilizada(it) }
            if (sirenesAtivas > 0) {
                StatusChip(
                    icon = Icons.Default.Warning,
                    text = "$sirenesAtivas ${localizationViewModel.getString("active")}",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .clip(RoundedCornerShape(12.dp))
            ) {
                GoogleMap(
                    modifier = Modifier.fillMaxSize(),
                    cameraPositionState = cameraPositionState,
                    properties = mapProperties,
                    uiSettings = mapUiSettings
                ) {
                    sirenes.forEach { sirene ->
                        sirene.coordinate?.let { coordinate ->
                            val isActive = isSireneMobilizada(sirene)
                            Marker(
                                state = MarkerState(position = coordinate),
                                title = sirene.nome,
                                icon = getMarkerIcon(isActive),
                                alpha = if (isActive) 1f else 0.7f
                            )
                        }
                    }
                }

                IconButton(
                    onClick = onExpand,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(8.dp)
                        .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.8f), CircleShape)
                ) {
                    Icon(Icons.Default.OpenInFull, localizationViewModel.getString("expand_map"), modifier = Modifier.size(20.dp))
                }

                FloatingActionButton(
                    onClick = {
                        userLocation?.let { location ->
                            scope.launch { cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 14f)) }
                        }
                    },
                    modifier = Modifier.align(Alignment.BottomEnd).padding(8.dp).size(40.dp),
                    elevation = FloatingActionButtonDefaults.elevation(defaultElevation = 2.dp),
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.MyLocation, localizationViewModel.getString("center_on_my_location"), modifier = Modifier.size(20.dp))
                }
            }
        }
    }
}

@Composable
private fun StatusChip(icon: ImageVector, text: String, color: Color) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.1f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, null, tint = color, modifier = Modifier.size(16.dp))
            Text(text, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurface)
        }
    }
}

private fun isSireneMobilizada(sirene: Sirene): Boolean {
    val status = sirene.status?.lowercase() ?: return false
    return status.contains("acionada") || status.contains("mobilizada")
}

private fun getMarkerIcon(isActive: Boolean): BitmapDescriptor {
    return if (isActive) {
        BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)
    } else {
        BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE)
    }
}