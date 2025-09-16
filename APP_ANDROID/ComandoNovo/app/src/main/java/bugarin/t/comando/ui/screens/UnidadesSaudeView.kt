package bugarin.t.comando.ui.screens

import android.content.Intent
import android.location.Location
import android.util.Log
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.PontoDeApoio
import bugarin.t.comando.ui.utils.rememberInteractiveMapProperties
import bugarin.t.comando.ui.utils.rememberInteractiveMapUiSettings
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@Composable
fun UnidadesSaudeView(
    unidades: List<PontoDeApoio>,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    // ❌ REMOVIDO: A instanciação local do 'LocationManager' foi removida para evitar vazamentos.

    var searchText by remember { mutableStateOf("") }
    var unidadeSelecionada by remember { mutableStateOf<PontoDeApoio?>(null) }
    var displayableUnidades by remember { mutableStateOf(unidades.filter { it.coordinate != null }) }

    LaunchedEffect(unidades) {
        Log.d("DEBUG_UNIDADES", "Unidades recebidas na View: ${unidades.size}")
        if (unidades.isNotEmpty()) {
            val unidadesComCoordenadas = unidades.count { it.coordinate != null }
            Log.d("DEBUG_UNIDADES", "Dessas, ${unidadesComCoordenadas} têm coordenadas válidas.")
            Log.d("DEBUG_UNIDADES", "Primeira unidade recebida (inspeção): ${unidades.first()}")
        }
    }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            LatLng(-22.908333, -43.196388), // Centro do Rio de Janeiro
            12f
        )
    }

    // ✅ ATUALIZADO: Consome a localização diretamente do ViewModel.
    val userLocation by localizationViewModel.userLocation.collectAsStateWithLifecycle()
    val unidadesProximas = remember(unidades, userLocation) {
        val location = userLocation ?: return@remember unidades.filter { it.coordinate != null }

        val quantidadeMaxima = 50

        unidades
            .filter { it.coordinate != null }
            .sortedBy { unidade ->
                val distancia = FloatArray(1)
                Location.distanceBetween(
                    location.latitude,
                    location.longitude,
                    unidade.coordinate!!.latitude,
                    unidade.coordinate!!.longitude,
                    distancia
                )
                distancia[0]
            }
            .take(quantidadeMaxima)
    }
    // Filtra as unidades com base no texto de busca.
    LaunchedEffect(searchText, unidades) {
        displayableUnidades = if (searchText.isBlank()) {
            unidades.filter { it.coordinate != null }
        } else {
            unidades.filter { unidade ->
                unidade.coordinate != null &&
                        (unidade.nome?.contains(searchText, ignoreCase = true) == true ||
                                unidade.endereco?.contains(searchText, ignoreCase = true) == true)
            }
        }
    }

    // Move a câmera para a localização do usuário quando ela fica disponível.
    LaunchedEffect(userLocation) {
        userLocation?.let { location ->
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 15f)
            )
        }
    }

    // ✅ NOVO: Pede ao ViewModel para iniciar as atualizações de localização.
    // O ViewModel gerencia o ciclo de vida, garantindo que as atualizações parem quando não forem mais necessárias.
    LaunchedEffect(Unit) {
        localizationViewModel.startLocationUpdates()
    }

    // Usa as funções seguras para configurar o mapa, evitando crashes de permissão.
    val mapProperties = rememberInteractiveMapProperties()
    val mapUiSettings = rememberInteractiveMapUiSettings()

    // ✅ CORRIGIDO: Adiciona coroutineScope para usar nas animações
    val coroutineScope = rememberCoroutineScope()

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
                displayableUnidades.forEach { unidade ->
                    unidade.coordinate?.let { coordinate ->
                        MarkerComposable(
                            state = MarkerState(position = coordinate),
                            title = unidade.nome,
                            onClick = {
                                unidadeSelecionada = unidade
                                true // Consome o clique para evitar o comportamento padrão do mapa
                            }
                        ) {
                            HealthUnitAnnotationView(isSelected = (unidadeSelecionada?.id == unidade.id))
                        }
                    }
                }
            }

            // UI sobre o mapa (cabeçalho, barra de busca, botões)
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
                                text = localizationViewModel.getString("health_units"),
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
                        OutlinedTextField(
                            value = searchText,
                            onValueChange = { searchText = it },
                            modifier = Modifier.fillMaxWidth(),
                            placeholder = { Text(localizationViewModel.getString("search_unit_placeholder")) },
                            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                            trailingIcon = {
                                if (searchText.isNotEmpty()) {
                                    IconButton(onClick = { searchText = "" }) {
                                        Icon(Icons.Default.Clear, contentDescription = localizationViewModel.getString("clear"))
                                    }
                                }
                            },
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                BottomBarView(
                    centerAction = {
                        // ✅ CORRIGIDO: Usa coroutineScope.launch para chamar a função suspend
                        coroutineScope.launch {
                            userLocation?.let { location ->
                                cameraPositionState.animate(
                                    CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 15f)
                                )
                            }
                        }
                    },
                    localizationViewModel = localizationViewModel
                )
            }

            // Bottom sheet com detalhes da unidade selecionada
            unidadeSelecionada?.let { unidade ->
                UnidadeDetalheView(
                    unidade = unidade,
                    userLocation = userLocation,
                    onDismiss = { unidadeSelecionada = null },
                    localizationViewModel = localizationViewModel
                )
            }
        }
    }
}

@Composable
private fun BottomBarView(
    centerAction: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        horizontalArrangement = Arrangement.End
    ) {
        FloatingActionButton(
            onClick = centerAction,
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun UnidadeDetalheView(
    unidade: PontoDeApoio,
    userLocation: Location?,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)

    val distance = remember(userLocation, unidade) {
        userLocation?.let { loc ->
            unidade.coordinate?.let { coord ->
                val results = FloatArray(1)
                Location.distanceBetween(loc.latitude, loc.longitude, coord.latitude, coord.longitude, results)
                results[0]
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Text(
                text = unidade.nome ?: localizationViewModel.getString("health_unit"),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )

            unidade.endereco?.let { InfoRow(localizationViewModel.getString("address"), it) }
            distance?.let { InfoRow(localizationViewModel.getString("distance_approx"), formatDistance(it)) }

            Button(
                onClick = {
                    unidade.coordinate?.let { coordinate ->
                        val gmmIntentUri = android.net.Uri.parse("google.navigation:q=${coordinate.latitude},${coordinate.longitude}")
                        val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri).setPackage("com.google.android.apps.maps")
                        context.startActivity(mapIntent)
                    }
                },
                modifier = Modifier.fillMaxWidth().height(50.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Directions, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text(localizationViewModel.getString("get_directions_map"), fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.navigationBarsPadding())
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(text = value, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
fun HealthUnitAnnotationView(isSelected: Boolean) {
    val size = if (isSelected) 44.dp else 36.dp
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .shadow(
                elevation = if (isSelected) 8.dp else 4.dp,
                shape = CircleShape,
                spotColor = Color.Red.copy(alpha = 0.5f)
            )
            .size(size)
            .background(Color.White, CircleShape)
    ) {
        Icon(
            imageVector = Icons.Default.LocalHospital,
            contentDescription = null,
            modifier = Modifier.size(size * 0.55f),
            tint = Color.Red
        )
    }
}

private fun formatDistance(meters: Float): String {
    return if (meters < 1000) {
        String.format(java.util.Locale.getDefault(), "%.0f m", meters)
    } else {
        String.format(java.util.Locale.getDefault(), "%.1f km", meters / 1000)
    }
}