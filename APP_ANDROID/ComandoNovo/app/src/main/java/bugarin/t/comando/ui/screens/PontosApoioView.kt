@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.content.Intent
import android.location.Location
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.PontoDeApoio
import bugarin.t.comando.ui.utils.rememberInteractiveMapProperties
import bugarin.t.comando.ui.utils.rememberInteractiveMapUiSettings
import bugarin.t.comando.ui.utils.zoomToCommunity // ✅ NOVO: Import da função utilitária
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@Composable
fun PontosApoioView(
    pontos: List<PontoDeApoio>,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ❌ REMOVIDO: A instanciação local do 'LocationManager' foi removida.
    // val locationManager = remember { LocationManager(context) }

    var comunidadeSelecionada by remember { mutableStateOf("") }
    var pontoSelecionado by remember { mutableStateOf<PontoDeApoio?>(null) }
    var hasInitializedToUserLocation by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val currentLanguage by localizationViewModel.currentLanguage.collectAsStateWithLifecycle()
    val allCommunitiesString = remember(currentLanguage) {
        localizationViewModel.getString("all_communities")
    }

    val comunidades = remember(pontos, allCommunitiesString) {
        val todasComunidades = pontos.mapNotNull { it.loc }.distinct().sorted()
        listOf(allCommunitiesString) + todasComunidades
    }

    val filteredPontos = remember(pontos, comunidadeSelecionada, allCommunitiesString) {
        if (comunidadeSelecionada.isEmpty() || comunidadeSelecionada == allCommunitiesString) {
            pontos
        } else {
            pontos.filter { it.loc == comunidadeSelecionada }
        }
    }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(-22.908333, -43.196388), 12f)
    }

    LaunchedEffect(comunidades) {
        if (comunidadeSelecionada.isEmpty() && comunidades.isNotEmpty()) {
            comunidadeSelecionada = comunidades.first()
        }
    }

    // ✅ ATUALIZADO: Consome a localização diretamente do ViewModel.
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()

    // ✅ NOVO: Pede ao ViewModel para iniciar as atualizações de localização quando a tela é exibida.
    LaunchedEffect(Unit) {
        localizationViewModel.startLocationUpdates()
    }

    // Centraliza no usuário uma única vez
    LaunchedEffect(userLocation) {
        if (!hasInitializedToUserLocation && userLocation != null) {
            userLocation?.let { location ->
                cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 15f))
                hasInitializedToUserLocation = true
            }
        }
    }

    val mapProperties = rememberInteractiveMapProperties()
    val mapUiSettings = rememberInteractiveMapUiSettings()

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            GoogleMap(
                modifier = Modifier.fillMaxSize(),
                cameraPositionState = cameraPositionState,
                properties = mapProperties,
                uiSettings = mapUiSettings
            ) {
                filteredPontos.forEach { ponto ->
                    ponto.coordinate?.let { coordinate ->
                        Marker(
                            state = MarkerState(position = coordinate),
                            title = ponto.nome,
                            snippet = ponto.endereco,
                            onClick = {
                                pontoSelecionado = ponto
                                scope.launch {
                                    cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(coordinate, 16f))
                                }
                                true // Consome o clique
                            }
                        )
                    }
                }
            }

            Column(modifier = Modifier.fillMaxSize()) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                    shadowElevation = 4.dp
                ) {
                    Column(
                        modifier = Modifier.statusBarsPadding().padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = localizationViewModel.getString("support_points"),
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold
                            )
                            IconButton(onClick = onDismiss) {
                                Icon(Icons.Default.Close, contentDescription = localizationViewModel.getString("close"))
                            }
                        }

                        var expanded by remember { mutableStateOf(false) }
                        ExposedDropdownMenuBox(
                            expanded = expanded,
                            onExpandedChange = { expanded = it }
                        ) {
                            OutlinedTextField(
                                value = comunidadeSelecionada,
                                onValueChange = {},
                                readOnly = true,
                                label = { Text(localizationViewModel.getString("filter_by_community")) },
                                modifier = Modifier.menuAnchor().fillMaxWidth(),
                                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                                singleLine = true
                            )
                            ExposedDropdownMenu(
                                expanded = expanded,
                                onDismissRequest = { expanded = false }
                            ) {
                                comunidades.forEach { comunidade ->
                                    DropdownMenuItem(
                                        text = { Text(comunidade) },
                                        onClick = {
                                            comunidadeSelecionada = comunidade
                                            expanded = false
                                            // ✅ ATUALIZADO: Usa a função utilitária reutilizável.
                                            scope.launch {
                                                zoomToCommunity(
                                                    communityToFilter = comunidade,
                                                    allCommunitiesIdentifier = allCommunitiesString,
                                                    items = pontos,
                                                    cameraPositionState = cameraPositionState
                                                )
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.End
                ) {
                    FloatingActionButton(
                        onClick = {
                            userLocation?.let { location ->
                                scope.launch {
                                    cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 15f))
                                }
                            }
                        },
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.primary
                    ) {
                        Icon(Icons.Default.MyLocation, contentDescription = localizationViewModel.getString("center_on_my_location"))
                    }
                }
            }

            pontoSelecionado?.let { ponto ->
                PontoApoioDetailsSheet(
                    ponto = ponto,
                    userLocation = userLocation,
                    onDismiss = { pontoSelecionado = null },
                    localizationViewModel = localizationViewModel
                )
            }
        }
    }
}

@Composable
private fun PontoApoioDetailsSheet(
    ponto: PontoDeApoio,
    userLocation: Location?,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val context = LocalContext.current
    val distance = remember(userLocation, ponto) {
        userLocation?.let { location ->
            ponto.coordinate?.let { coordinate ->
                val results = FloatArray(1)
                Location.distanceBetween(location.latitude, location.longitude, coordinate.latitude, coordinate.longitude, results)
                results[0]
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = ponto.nome ?: localizationViewModel.getString("support_point"),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            HorizontalDivider()
            InfoRow(Icons.Default.LocationOn, localizationViewModel.getString("address"), ponto.endereco ?: localizationViewModel.getString("not_available"))
            ponto.loc?.let { loc -> InfoRow(Icons.Default.LocationCity, localizationViewModel.getString("community"), loc) }
            distance?.let { dist -> InfoRow(Icons.Default.Route, localizationViewModel.getString("distance"), formatDistance(dist)) }
            HorizontalDivider()
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = {
                        ponto.coordinate?.let { coordinate ->
                            val gmmIntentUri = Uri.parse("google.navigation:q=${coordinate.latitude},${coordinate.longitude}")
                            val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri).setPackage("com.google.android.apps.maps")
                            context.startActivity(mapIntent)
                        }
                    },
                    modifier = Modifier.weight(1f).height(50.dp)
                ) {
                    Icon(Icons.Default.Directions, contentDescription = null, modifier = Modifier.size(20.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(localizationViewModel.getString("get_directions"))
                }
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f).height(50.dp)
                ) {
                    Text(localizationViewModel.getString("close"))
                }
            }
            Spacer(modifier = Modifier.navigationBarsPadding())
        }
    }
}

@Composable
private fun InfoRow(icon: ImageVector, label: String, value: String) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(20.dp).padding(top = 2.dp)
        )
        Column {
            Text(text = label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(text = value, style = MaterialTheme.typography.bodyLarge)
        }
    }
}

private fun formatDistance(meters: Float): String {
    return if (meters < 1000) {
        String.format(java.util.Locale.getDefault(), "%.0f m", meters)
    } else {
        String.format(java.util.Locale.getDefault(), "%.1f km", meters / 1000)
    }
}

// ❌ REMOVIDO: A função de zoom local foi removida em favor da versão utilitária reutilizável.