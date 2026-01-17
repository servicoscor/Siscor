@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import bugarin.t.comando.R
import bugarin.t.comando.data.Alerta
import bugarin.t.comando.data.Camera
import bugarin.t.comando.data.CategoriaPonto
import bugarin.t.comando.data.LocalizedText
import bugarin.t.comando.data.PontoTuristico
import bugarin.t.comando.ui.components.*
import bugarin.t.comando.ui.components.RedesSociaisCardView
import bugarin.t.comando.ui.utils.rememberLocationPermissionState
import bugarin.t.comando.viewmodel.CORViewModel
import bugarin.t.comando.viewmodel.InterdicoesViewModel
import bugarin.t.comando.viewmodel.LocalizationViewModel
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import com.google.android.gms.maps.model.LatLng

@Composable
fun MainScreen(
    viewModel: CORViewModel,
    localizationViewModel: LocalizationViewModel,
    interdicoesViewModel: InterdicoesViewModel,
    navController: NavController,
    onNavigateToAlertaDetalhes: (Alerta) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current
    val context = LocalContext.current

    var expandedScreen by remember { mutableStateOf<ExpandedScreen?>(null) }
    var showCamerasFullScreen by remember { mutableStateOf(false) }

    // ✅ SharedPreferences para salvar favoritos
    val sharedPrefs = remember {
        context.getSharedPreferences("camera_prefs", Context.MODE_PRIVATE)
    }

    // Carregar favoritos salvos quando o app inicia
    val favoriteCameraIds = remember {
        val savedFavorites = sharedPrefs.getStringSet("favorite_cameras", emptySet()) ?: emptySet()
        mutableStateListOf(*savedFavorites.toTypedArray())
    }

    // Função para salvar e alternar favorito
    fun toggleFavorite(cameraId: String) {
        if (favoriteCameraIds.contains(cameraId)) {
            favoriteCameraIds.remove(cameraId)
        } else {
            // Limitar a 2 favoritos
            if (favoriteCameraIds.size >= 2) {
                favoriteCameraIds.removeAt(0) // Remove o primeiro
            }
            favoriteCameraIds.add(cameraId)
        }

        // ✅ SALVAR NO SHAREDPREFERENCES
        sharedPrefs.edit()
            .putStringSet("favorite_cameras", favoriteCameraIds.toSet())
            .apply()
    }

    // Estado para controlar o popup de nível de calor
    var showHeatLevelPopup by remember { mutableStateOf(false) }

    // PERMISSION: Usando utility function otimizada
    val permissionState = rememberLocationPermissionState()

    // Estado local para pontos turísticos (sem ViewModel)
    var pontosLocais by remember { mutableStateOf<List<PontoTuristico>>(emptyList()) }
    var isLoadingPontos by remember { mutableStateOf(false) }

    // PERFORMANCE: Camera selection handler com tipo explícito
    val handleCameraSelection: (Camera) -> Unit = remember {
        { camera: Camera ->
            try {
                navController.navigate("camera_detail/${camera.apiId}")
            } catch (e: Exception) {
                android.util.Log.e("MainScreen", "Navigation failed: ${e.message}")
            }
        }
    }

    // Calcular topPadding FORA do remember
    val statusBarPadding = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val topPadding = statusBarPadding + 56.dp

    // MEMORY: Cleanup quando componente é removido
    DisposableEffect(Unit) {
        onDispose {
            android.util.Log.d("MainScreen", "Cleaning up main screen")
        }
    }

    // Background resource calculado sem composable calls
    val backgroundResource = remember(uiState.nomeImagemFundo) {
        getBackgroundResource(uiState.nomeImagemFundo)
    }

    // Função para carregar pontos turísticos
    fun loadPontosTuristicos() {
        scope.launch {
            isLoadingPontos = true
            try {
                delay(1000) // Simula delay de rede
                pontosLocais = getExemplosPontosTuristicos()
            } catch (e: Exception) {
                android.util.Log.e("MainScreen", "Erro ao carregar pontos: ${e.message}")
            } finally {
                isLoadingPontos = false
            }
        }
    }

    // Função para verificar nível de calor e navegar
    fun handleHeatLevelNavigation() {
        val nivelCalor = uiState.nivelCalor?.situacao ?: ""
        val nivelNumerico = when {
            nivelCalor.contains("1") || nivelCalor.lowercase().contains("um") -> 1
            nivelCalor.contains("2") || nivelCalor.lowercase().contains("dois") -> 2
            nivelCalor.contains("3") || nivelCalor.lowercase().contains("três") || nivelCalor.lowercase().contains("tres") -> 3
            nivelCalor.contains("4") || nivelCalor.lowercase().contains("quatro") -> 4
            nivelCalor.contains("5") || nivelCalor.lowercase().contains("cinco") -> 5
            else -> 0
        }
        android.util.Log.e("MainScreen", "Numero: ${nivelNumerico}")

        // IF PRINCIPAL: Verificar se pode navegar
        if (nivelNumerico >= 4) {
            try {
                navController.navigate("heat_details") // Substitua pela rota correta
            } catch (e: Exception) {
                android.util.Log.e("MainScreen", "Heat navigation failed: ${e.message}")
            }
        } else {
            showHeatLevelPopup = true
        }
    }

    // Funções de navegação e controle
    fun expandCameras() {
        showCamerasFullScreen = true
    }

    fun dismissCameras() {
        showCamerasFullScreen = false
    }

    fun dismissExpandedScreen() {
        expandedScreen = null
    }

    fun setAlarmeScreen() {
        expandedScreen = ExpandedScreen.ALARME
    }

    fun setPontosApoioScreen() {
        expandedScreen = ExpandedScreen.PONTOS_APOIO
    }

    fun setInterdicoesScreen() {
        expandedScreen = ExpandedScreen.INTERDICOES
    }

    fun scrollToAlerts() {
        scope.launch {
            try {
                val targetIndex = 4
                val offsetPx = with(density) { -topPadding.roundToPx() }
                scrollState.animateScrollToItem(
                    index = targetIndex,
                    scrollOffset = offsetPx
                )
            } catch (e: Exception) {
                android.util.Log.w("MainScreen", "Scroll to alerts failed: ${e.message}")
            }
        }
    }

    fun setUnidadesSaudeScreen() {
        expandedScreen = ExpandedScreen.UNIDADES_SAUDE
    }

    fun setPontosTuristicosScreen() {
        expandedScreen = ExpandedScreen.PONTOS_TURISTICOS
        loadPontosTuristicos() // Carrega quando abre a tela
    }

    fun openRioturSite() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://riotur.rio/"))
        if (context !is android.app.Activity) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun callDefesaCivil() {
        val intent = Intent(Intent.ACTION_DIAL).apply {
            data = Uri.parse("tel:199")
        }
        if (context !is android.app.Activity) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun scrollToEvents() {
        scope.launch {
            try {
                val targetIndex = 5
                val offsetPx = with(density) { -topPadding.roundToPx() }
                scrollState.animateScrollToItem(
                    index = targetIndex,
                    scrollOffset = offsetPx
                )
            } catch (e: Exception) {
                android.util.Log.w("MainScreen", "Scroll to events failed: ${e.message}")
            }
        }
    }

    fun navigateToRadar() {
        try {
            navController.navigate("radar_fullscreen")
        } catch (e: Exception) {
            android.util.Log.e("MainScreen", "Radar navigation failed: ${e.message}")
        }
    }

    fun navigateToCarnaval() {
        try {
            navController.navigate("carnaval_fullscreen")
        } catch (e: Exception) {
            android.util.Log.e("MainScreen", "Carnaval navigation failed: ${e.message}")
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // PERFORMANCE: Background image otimizado
        Image(
            painter = painterResource(id = backgroundResource),
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.3f))
        )

        LazyColumn(
            state = scrollState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = topPadding + 16.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            item(key = "estagio") {
                EstagioView(uiState.currentStage, localizationViewModel)
            }

            item(key = "clima") {
                // PERFORMANCE: Cached CondicaoClimatica computation
                val condicaoClimatica = remember(
                    uiState.estacoesChuva,
                    uiState.estacoesMeteorologicas,
                    uiState.nivelCalor,
                    uiState.isDataLoaded
                ) {
                    if (uiState.isDataLoaded) {
                        val chuvaMax = uiState.estacoesChuva.maxOfOrNull { estacao ->
                            estacao.chuva1 ?: 0f
                        } ?: 0f
                        val velocidadesVento = uiState.estacoesMeteorologicas.mapNotNull { estacao ->
                            estacao.velMed
                        }
                        val ventoMediaKmh = velocidadesVento.takeIf { it.isNotEmpty() }?.average()?.let { it * 3.6 }
                        val ventoValor = ventoMediaKmh?.let { "%.0f km/h".format(it) }
                            ?: localizationViewModel.getString("not_available_short")

                        CondicaoClimatica(
                            calorValor = uiState.nivelCalor?.situacao ?: localizationViewModel.getString("status_normal"),
                            calorTitulo = localizationViewModel.getString("heat_level"),
                            chuvaValor = if (chuvaMax > 0) "%.1f mm".format(chuvaMax) else localizationViewModel.getString("rain_none"),
                            chuvaTitulo = localizationViewModel.getString("rain"),
                            ventoValor = ventoValor,
                            ventoTitulo = localizationViewModel.getString("wind"),
                            isChovendo = chuvaMax > 0
                        )
                    } else null
                }

                ClimaCardView(
                    condicaoClimatica = condicaoClimatica,
                    isLoading = uiState.isLoading,
                    navController = navController,
                    localizationViewModel = localizationViewModel,
                    onHeatLevelClick = ::handleHeatLevelNavigation
                )
            }

            item(key = "cameras") {
                CamerasMapView(
                    cameras = uiState.cameras,
                    isLocationPermissionGranted = permissionState.hasPermission,
                    onExpand = ::expandCameras,
                    onCameraSelected = handleCameraSelection,
                    localizationViewModel = localizationViewModel,
                    favoriteCameraIds = favoriteCameraIds,
                    onToggleFavorite = ::toggleFavorite,
                    onFavoriteClick = handleCameraSelection,
                    onSelectCameraForFavorite = handleCameraSelection
                )
            }

            item(key = "radar") {
                RadarCardView(
                    onExpand = ::navigateToRadar,
                    localizationViewModel = localizationViewModel
                )
            }

            item(key = "alertas") {
                AlertasCardView(
                    alertas = uiState.alertas,
                    isLoading = uiState.isLoading,
                    onAlertaClick = onNavigateToAlertaDetalhes,
                    localizationViewModel = localizationViewModel
                )
            }

            item(key = "carnaval_2026") {
                CarnavalCardView(
                    onOpen = ::navigateToCarnaval,
                    localizationViewModel = localizationViewModel
                )
            }

            item(key = "redes_sociais") {
                RedesSociaisCardView()
            }

            item(key = "botoes_inferiores") {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(modifier = Modifier.weight(1f)) {
                            FuncaoButton(
                                iconVector = Icons.Default.Phone,
                                labelText = localizationViewModel.getString("call_civil_defense"),
                                onClick = ::callDefesaCivil
                            )
                        }
                        Box(modifier = Modifier.weight(1f)) {
                            PontosApoioButton(
                                action = ::setPontosApoioScreen,
                                localizationViewModel = localizationViewModel
                            )
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(modifier = Modifier.weight(1f)) {
                            FuncaoButton(
                                iconVector = Icons.Default.LocalHospital,
                                labelText = localizationViewModel.getString("health_units"),
                                onClick = ::setUnidadesSaudeScreen
                            )
                        }
                        Box(modifier = Modifier.weight(1f)) {
                            SirenesStatusButton(
                                action = ::setAlarmeScreen,
                                sirenes = uiState.sirenes,
                                localizationViewModel = localizationViewModel
                            )
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(modifier = Modifier.weight(1f)) {
                            FuncaoButton(
                                iconVector = Icons.Default.Block,
                                labelText = localizationViewModel.getString("interdictions"),
                                onClick = ::setInterdicoesScreen,
                                subtitleText = localizationViewModel.getString("blocked_roads")
                            )
                        }
                        Box(modifier = Modifier.weight(1f)) {
                            FuncaoButton(
                                iconVector = Icons.Default.Landscape,
                                labelText = localizationViewModel.getString("tourist_spots"),
                                onClick = ::openRioturSite
                            )
                        }
                    }
                }
            }
        }

        HeaderView(
            currentStage = uiState.currentStage,
            alertCount = uiState.alertas.size,
            eventCount = uiState.eventos.size,
            scrollToAlerts = ::scrollToAlerts,
            scrollToEvents = ::scrollToEvents,
            localizationViewModel = localizationViewModel,
            modifier = Modifier.align(Alignment.TopCenter)
        )
    }

    // Popup de aviso sobre nível de calor
    if (showHeatLevelPopup) {
        Dialog(
            onDismissRequest = { showHeatLevelPopup = false },
            properties = DialogProperties(
                dismissOnBackPress = true,
                dismissOnClickOutside = true
            )
        ) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                shape = MaterialTheme.shapes.medium,
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Aviso",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "Este botão só será habilitado quando atingir Calor 4 ou superior.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    Button(
                        onClick = { showHeatLevelPopup = false },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        Text("Entendi")
                    }
                }
            }
        }
    }

    // PERFORMANCE: Gerenciamento otimizado das telas expandidas
    LaunchedEffect(expandedScreen) {
        if (expandedScreen != null) {
            android.util.Log.d("MainScreen", "Opening expanded screen: $expandedScreen")
        }
    }

    // When expression com todos os casos do enum
    when (expandedScreen) {
        ExpandedScreen.ALARME -> {
            SistemaAlarmeFullScreenView(
                sirenes = uiState.sirenes,
                onDismiss = ::dismissExpandedScreen,
                localizationViewModel = localizationViewModel
            )
        }

        ExpandedScreen.PONTOS_APOIO -> {
            PontosApoioView(
                pontos = uiState.pontosDeApoio,
                onDismiss = ::dismissExpandedScreen,
                localizationViewModel = localizationViewModel
            )
        }

        ExpandedScreen.UNIDADES_SAUDE -> {
            UnidadesSaudeView(
                unidades = uiState.unidadesDeSaude,
                onDismiss = ::dismissExpandedScreen,
                localizationViewModel = localizationViewModel
            )
        }

        ExpandedScreen.PONTOS_TURISTICOS -> {
            PontosTuristicosView(
                onDismiss = ::dismissExpandedScreen,
                localizationViewModel = localizationViewModel,
                pontos = pontosLocais,
                isLoading = isLoadingPontos
            )
        }

        ExpandedScreen.INTERDICOES -> {
            InterdicoesView(
                onDismiss = ::dismissExpandedScreen,
                localizationViewModel = localizationViewModel,
                viewModel = interdicoesViewModel
            )
        }

        null -> {
            // Nothing to show
        }
    }

    // Function reference para cameras fullscreen
    if (showCamerasFullScreen) {
        CamerasMapFullScreen(
            cameras = uiState.cameras,
            isLocationPermissionGranted = permissionState.hasPermission,
            onDismiss = ::dismissCameras,
            onCameraSelected = handleCameraSelection,
            localizationViewModel = localizationViewModel,
            favoriteCameraIds = favoriteCameraIds,
            onToggleFavorite = ::toggleFavorite
        )
    }
}

private enum class ExpandedScreen {
    ALARME, PONTOS_APOIO, UNIDADES_SAUDE, PONTOS_TURISTICOS, INTERDICOES
}

// ✅ FUNÇÃO PARA DADOS DE EXEMPLO DOS PONTOS TURÍSTICOS
private fun getExemplosPontosTuristicos(): List<PontoTuristico> {
    return listOf(
        PontoTuristico(
            id = "1",
            nomeLocalizado = LocalizedText(
                pt = "Cristo Redentor",
                en = "Christ the Redeemer",
                es = "Cristo Redentor",
                fr = "Christ Rédempteur",
                zh = "救世基督像"
            ),
            categoria = CategoriaPonto.PATRIMONIO,
            textoLocalizado = LocalizedText(
                pt = "Uma das sete maravilhas do mundo moderno.",
                en = "One of the seven wonders of the modern world.",
                es = "Una de las siete maravillas del mundo moderno.",
                fr = "L'une des sept merveilles du monde moderne.",
                zh = "现代世界七大奇迹之一。"
            ),
            endereco = "Parque Nacional da Tijuca - Alto da Boa Vista, Rio de Janeiro",
            telefone = "(21) 2558-1329",
            website = "https://cristoredentoroficial.com.br",
            coordenadas = LatLng(-22.9519, -43.2105),
            avaliacao = 4.8f
        )
    )
}

// ✅ FUNÇÃO PARA OBTER BACKGROUND RESOURCE
private fun getBackgroundResource(imageName: String): Int {
    return when (imageName) {
        "chuva_noite" -> R.drawable.chuva_noite
        "chuva_dia" -> R.drawable.chuva_dia
        "noite_claro_p" -> R.drawable.noite_claro_p
        "dia_claro_p" -> R.drawable.dia_claro_p
        "noite_nuvens_p" -> R.drawable.noite_nuvens_p
        "dia_nuvens_p" -> R.drawable.dia_nuvens_p
        "noite_nublado_p" -> R.drawable.noite_nublado_p
        "dia_nublado_p" -> R.drawable.dia_nublado_p
        else -> R.drawable.dia_claro_p
    }
}