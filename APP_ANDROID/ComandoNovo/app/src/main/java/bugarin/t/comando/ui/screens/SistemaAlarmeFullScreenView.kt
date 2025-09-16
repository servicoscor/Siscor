package bugarin.t.comando.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.Sirene
import bugarin.t.comando.ui.utils.rememberInteractiveMapProperties
import bugarin.t.comando.ui.utils.rememberInteractiveMapUiSettings
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import kotlinx.coroutines.launch

@Composable
fun SistemaAlarmeFullScreenView(
    sirenes: List<Sirene>,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.908333, -43.196388), 12f)
    }
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()
    val coroutineScope = rememberCoroutineScope()

    // Pede ao ViewModel para iniciar as atualizações de localização
    LaunchedEffect(Unit) {
        localizationViewModel.startLocationUpdates()
    }

    // Move a câmera para a localização do usuário quando ela fica disponível
    LaunchedEffect(userLocation) {
        userLocation?.let { location ->
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 15f)
            )
        }
    }

    val mapProperties = rememberInteractiveMapProperties()
    val mapUiSettings = rememberInteractiveMapUiSettings()

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false // Ocupa a tela inteira
        )
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
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

            // UI sobre o mapa (cabeçalho, botões)
            Column(modifier = Modifier.fillMaxSize()) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                    shadowElevation = 4.dp
                ) {
                    Row(
                        modifier = Modifier
                            .statusBarsPadding()
                            .padding(16.dp)
                            .fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = localizationViewModel.getString("alarm_system"),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        IconButton(onClick = onDismiss) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = localizationViewModel.getString("close")
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                // Botão para centralizar no usuário
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.End
                ) {
                    FloatingActionButton(
                        onClick = {
                            userLocation?.let { location ->
                                coroutineScope.launch {
                                    cameraPositionState.animate(
                                        CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 15f)
                                    )
                                }
                            }
                        },
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.primary
                    ) {
                        Icon(
                            imageVector = Icons.Default.MyLocation,
                            contentDescription = localizationViewModel.getString("center_on_my_location")
                        )
                    }
                }
            }
        }
    }
}

// Funções de ajuda (podem ficar no mesmo arquivo ou em um arquivo de utils)
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