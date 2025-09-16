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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.EstacaoChuva
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
fun ChuvaDetalhesScreen(
    // ✅ ARQUITETURA: Recebe os dados diretamente, em vez de depender de um ViewModel próprio.
    estacoes: List<EstacaoChuva>,
    onBackClick: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ✅ ROBUSTEZ: Gerenciamento seguro da barra de status com limpeza automática.
    val view = LocalView.current
    if (!view.isInEditMode) {
        val window = (view.context as Activity).window
        val originalStatusBarColor = remember { window.statusBarColor }
        val originalIsLight = remember { WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars }
        DisposableEffect(Unit) {
            window.statusBarColor = Color.Black.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
            onDispose {
                window.statusBarColor = originalStatusBarColor
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = originalIsLight
            }
        }
    }

    val scope = rememberCoroutineScope()
    var selectedEstacao by remember { mutableStateOf<EstacaoChuva?>(null) }
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

    LaunchedEffect(userLocation) {
        userLocation?.let { location ->
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 12f)
            )
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = rememberInteractiveMapProperties().copy(isMyLocationEnabled = permissionState.hasPermission),
            uiSettings = rememberInteractiveMapUiSettings().copy(myLocationButtonEnabled = false)
        ) {
            estacoes.forEach { estacao ->
                estacao.coordinate?.let { coord ->
                    val chuva1h = estacao.chuva1 ?: 0f
                    Marker(
                        state = MarkerState(position = coord),
                        title = estacao.nome,
                        snippet = "1h: %.1f mm".format(chuva1h),
                        icon = BitmapDescriptorFactory.defaultMarker(getRainMarkerHue(chuva1h)),
                        onClick = {
                            selectedEstacao = estacao
                            scope.launch { bottomSheetState.show() }
                            true
                        }
                    )
                }
            }
        }

        Column(modifier = Modifier.fillMaxSize()) {
            HeaderChuva(localizationViewModel, onBackClick)
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
                Icon(if (permissionState.hasPermission) Icons.Default.MyLocation else Icons.Default.LocationDisabled, null)
            }
        }

        // Material 3 ModalBottomSheet instead of Material 2 ModalBottomSheetLayout
        if (selectedEstacao != null) {
            ModalBottomSheet(
                onDismissRequest = { selectedEstacao = null },
                sheetState = bottomSheetState,
                shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
            ) {
                selectedEstacao?.let { EstacaoDetalheSheet(it, localizationViewModel) }
            }
        }
    }
}

@Composable
private fun HeaderChuva(localizationViewModel: LocalizationViewModel, onBackClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier.statusBarsPadding().padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(localizationViewModel.getString("rain_stations"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f).padding(start = 16.dp))
            IconButton(onClick = onBackClick) { Icon(Icons.Default.Close, localizationViewModel.getString("close")) }
        }
    }
}

@Composable
private fun EstacaoDetalheSheet(estacao: EstacaoChuva, localizationViewModel: LocalizationViewModel) {
    Column(modifier = Modifier.navigationBarsPadding().padding(horizontal = 24.dp, vertical = 16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Default.LocationOn, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(24.dp))
            Column {
                Text(estacao.nome.orEmpty(), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Text("${estacao.municipio.orEmpty()} • ${estacao.fonte.orEmpty()}", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Spacer(modifier = Modifier.height(24.dp))
        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                PrecipitacaoRow(localizationViewModel.getString("rain_15min"), estacao.chuvaI, "mm")
                PrecipitacaoRow(localizationViewModel.getString("rain_1h"), estacao.chuva1, "mm", destaque = true)
                PrecipitacaoRow(localizationViewModel.getString("rain_4h"), estacao.chuva4, "mm")
                PrecipitacaoRow(localizationViewModel.getString("rain_24h"), estacao.chuva24, "mm")
                PrecipitacaoRow(localizationViewModel.getString("rain_96h"), estacao.chuva96, "mm")
            }
        }
        estacao.data?.let {
            Spacer(modifier = Modifier.height(16.dp))
            Text("${localizationViewModel.getString("last_update")}: $it", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.align(Alignment.CenterHorizontally))
        }
    }
}

@Composable
private fun PrecipitacaoRow(label: String, value: Float?, unit: String, destaque: Boolean = false) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = MaterialTheme.typography.bodyLarge, fontWeight = if (destaque) FontWeight.Medium else FontWeight.Normal, modifier = Modifier.weight(1f))
        Text(
            text = value?.let { "%.1f $unit".format(it) } ?: "- $unit",
            style = if (destaque) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodyLarge,
            fontWeight = if (destaque) FontWeight.Bold else FontWeight.Normal,
            color = if (destaque) getColorForRainLevel(value ?: 0f) else LocalContentColor.current
        )
    }
}

@Composable
private fun getColorForRainLevel(mm: Float): Color {
    // ✅ TEMATIZAÇÃO: Cores semânticas baseadas no tema.
    return when {
        mm == 0f -> MaterialTheme.colorScheme.tertiary // Sem chuva
        mm < 5f -> MaterialTheme.colorScheme.primary // Chuva leve
        mm < 25f -> Color(0xFFFF9800) // Laranja para alerta
        else -> MaterialTheme.colorScheme.error // Vermelho para perigo
    }
}

private fun getRainMarkerHue(mm: Float): Float {
    return when {
        mm == 0f -> BitmapDescriptorFactory.HUE_GREEN
        mm < 5f -> BitmapDescriptorFactory.HUE_AZURE
        mm < 25f -> BitmapDescriptorFactory.HUE_ORANGE
        else -> BitmapDescriptorFactory.HUE_RED
    }
}