@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.EstacaoMeteorologica
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
fun VentoDetalhesScreen(
    estacoes: List<EstacaoMeteorologica>, // Recebe as estações diretamente
    onBackClick: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ✅ ROBUSTEZ: Gerenciamento seguro da barra de status com limpeza automática.
    val view = LocalView.current
    if (!view.isInEditMode) {
        val window = (view.context as Activity).window
        val originalStatusBarColor = remember { window.statusBarColor }
        val originalLightStatusBars = remember { WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars }

        DisposableEffect(Unit) {
            // Aplica o estilo escuro ao entrar na tela
            window.statusBarColor = Color.Black.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false

            // Restaura o estilo original ao sair da tela
            onDispose {
                window.statusBarColor = originalStatusBarColor
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = originalLightStatusBars
            }
        }
    }

    val scope = rememberCoroutineScope()
    var selectedEstacao by remember { mutableStateOf<EstacaoMeteorologica?>(null) }
    val bottomSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // ✅ CONSISTÊNCIA: Usando o handler de permissão padrão do app.
    val permissionState = rememberLocationPermissionState { isGranted ->
        if (isGranted) localizationViewModel.startLocationUpdates()
    }
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.9083, -43.1963), 11f)
    }

    LaunchedEffect(Unit) {
        localizationViewModel.startLocationUpdates()
    }

    // Move a câmera para a localização do usuário uma vez
    LaunchedEffect(userLocation) {
        userLocation?.let { location ->
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 12f)
            )
        }
    }

    val mapProperties = rememberInteractiveMapProperties()
    val mapUiSettings = rememberInteractiveMapUiSettings()

    Box(modifier = Modifier.fillMaxSize()) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = mapProperties.copy(isTrafficEnabled = true),
            uiSettings = mapUiSettings
        ) {
            estacoes.forEach { estacao ->
                estacao.coordinate?.let { coord ->
                    val velocidadeKmh = (estacao.velMed ?: 0f) * 3.6f

                    Marker(
                        state = MarkerState(position = coord),
                        title = estacao.nome,
                        snippet = "%.1f km/h".format(velocidadeKmh),
                        icon = BitmapDescriptorFactory.defaultMarker(getWindMarkerHue(velocidadeKmh)),
                        onClick = {
                            selectedEstacao = estacao
                            scope.launch { bottomSheetState.show() }
                            true
                        }
                    )
                }
            }
        }

        // UI sobre o mapa
        Column(modifier = Modifier.fillMaxSize()) {
            HeaderVento(localizationViewModel, onBackClick)
            Spacer(Modifier.weight(1f))
            FloatingActionButton(
                onClick = {
                    if (permissionState.hasPermission) {
                        userLocation?.let { location ->
                            scope.launch {
                                cameraPositionState.animate(
                                    CameraUpdateFactory.newLatLngZoom(
                                        LatLng(location.latitude, location.longitude),
                                        14f
                                    )
                                )
                            }
                        }
                    } else {
                        permissionState.launchPermissionRequest()
                    }
                },
                modifier = Modifier.align(Alignment.End).navigationBarsPadding().padding(16.dp),
            ) {
                Icon(if (permissionState.hasPermission) Icons.Default.MyLocation else Icons.Default.LocationDisabled, localizationViewModel.getString("my_location"))
            }
        }
    }

    if (selectedEstacao != null) {
        ModalBottomSheet(
            onDismissRequest = { selectedEstacao = null },
            sheetState = bottomSheetState
        ) {
            EstacaoVentoDetalheSheet(selectedEstacao!!, localizationViewModel)
        }
    }
}

@Composable
private fun HeaderVento(localizationViewModel: LocalizationViewModel, onBackClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f),
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier.statusBarsPadding().padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(localizationViewModel.getString("wind_stations"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f).padding(start = 16.dp))
            IconButton(onClick = onBackClick) { Icon(Icons.Default.Close, localizationViewModel.getString("close")) }
        }
    }
}


@Composable
private fun EstacaoVentoDetalheSheet(estacao: EstacaoMeteorologica, localizationViewModel: LocalizationViewModel) {
    Column(
        modifier = Modifier.navigationBarsPadding().padding(horizontal = 24.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Default.Air, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(24.dp))
            Column {
                Text(estacao.nome ?: "Estação", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Text(estacao.fonte ?: "", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        HorizontalDivider()
        val velocidadeKmh = (estacao.velMed ?: 0f) * 3.6f
        DataRow(Icons.Default.Air, localizationViewModel.getString("wind_speed"), "%.1f km/h".format(velocidadeKmh), getColorForWindLevel(velocidadeKmh))
        DataRow(Icons.Default.Navigation, localizationViewModel.getString("wind_direction"), estacao.dirMed ?: "-", iconRotation = getDegreeFromDirection(estacao.dirMed ?: ""))
        DataRow(Icons.Default.Thermostat, localizationViewModel.getString("temperature"), estacao.temMed?.let { "%.1f°C".format(it) } ?: "-")
        DataRow(Icons.Default.WaterDrop, localizationViewModel.getString("humidity"), estacao.umdMed?.let { "%.0f%%".format(it) } ?: "-")
        estacao.data?.let {
            Text(
                text = "${localizationViewModel.getString("last_update")}: $it",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun DataRow(icon: ImageVector, label: String, value: String, valueColor: Color = MaterialTheme.colorScheme.onSurface, iconRotation: Float = 0f) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(24.dp).rotate(iconRotation))
        Spacer(Modifier.width(16.dp))
        Text(label, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = valueColor)
    }
}

@Composable
private fun getColorForWindLevel(kmh: Float): Color {
    return when {
        kmh < 10f -> Color(0xFF4CAF50)
        kmh < 20f -> Color(0xFF2196F3)
        kmh < 40f -> Color(0xFFFF9800)
        else -> Color(0xFFF44336)
    }
}

private fun getWindMarkerHue(kmh: Float): Float {
    return when {
        kmh < 10f -> BitmapDescriptorFactory.HUE_GREEN
        kmh < 20f -> BitmapDescriptorFactory.HUE_AZURE
        kmh < 40f -> BitmapDescriptorFactory.HUE_ORANGE
        else -> BitmapDescriptorFactory.HUE_RED
    }
}

private fun getDegreeFromDirection(direction: String): Float {
    return when (direction.uppercase()) {
        "N" -> 0f
        "NE" -> 45f
        "E" -> 90f
        "SE" -> 135f
        "S" -> 180f
        "SW", "SO" -> 225f
        "W", "O" -> 270f
        "NW", "NO" -> 315f
        else -> 0f
    }
}

// REMOVIDO: A criação de ícones customizados no Canvas foi removida por simplicidade
// e para evitar potencial sobrecarga de memória. Os marcadores coloridos padrão
// são mais performáticos e cumprem a mesma função visual.