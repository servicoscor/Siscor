@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
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
import bugarin.t.comando.viewmodel.LocalizationViewModel
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import com.google.android.gms.maps.model.LatLng

@Composable
fun MainScreen(
    viewModel: CORViewModel,
    localizationViewModel: LocalizationViewModel,
    navController: NavController,
    onNavigateToAlertaDetalhes: (Alerta) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current

    var expandedScreen by remember { mutableStateOf<ExpandedScreen?>(null) }
    var showCamerasFullScreen by remember { mutableStateOf(false) }

    // Estado local para favoritos de câmeras
    val favoriteCameraIds = remember { mutableStateListOf<String>() }
    fun toggleFavorite(cameraId: String) {
        if (favoriteCameraIds.contains(cameraId)) {
            favoriteCameraIds.remove(cameraId)
        } else {
            favoriteCameraIds.add(cameraId)
        }
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
                    uiState.currentStage,
                    uiState.nivelCalor,
                    uiState.isDataLoaded
                ) {
                    if (uiState.isDataLoaded) {
                        val chuvaMax = uiState.estacoesChuva.maxOfOrNull { estacao ->
                            estacao.chuva1 ?: 0f
                        } ?: 0f

                        CondicaoClimatica(
                            calorValor = uiState.nivelCalor?.situacao ?: localizationViewModel.getString("status_normal"),
                            calorTitulo = localizationViewModel.getString("heat_level"),
                            estagioValor = "ESTÁGIO ${uiState.currentStage}",
                            estagioTitulo = localizationViewModel.getString("stage"),
                            estagioNumero = uiState.currentStage,
                            chuvaValor = if (chuvaMax > 0) "%.1f mm".format(chuvaMax) else localizationViewModel.getString("rain_none"),
                            chuvaTitulo = localizationViewModel.getString("rain"),
                            isChovendo = chuvaMax > 0
                        )
                    } else null
                }

                ClimaCardView(
                    condicaoClimatica = condicaoClimatica,
                    isLoading = uiState.isLoading,
                    navController = navController,
                    localizationViewModel = localizationViewModel,
                    // Passar a função de validação para o ClimaCardView
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

            item(key = "mapa_alertas") {
                SistemaAlarmeMapView(
                    sirenes = uiState.sirenes,
                    onExpand = ::setAlarmeScreen,
                    localizationViewModel = localizationViewModel
                )
            }

            item(key = "redes_sociais") {
                RedesSociaisCardView()
            }

            item(key = "sirenes_pontos") {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Box(modifier = Modifier.weight(1f)) {
                        SirenesStatusButton(
                            action = ::setAlarmeScreen,
                            sirenes = uiState.sirenes,
                            localizationViewModel = localizationViewModel
                        )
                    }
                    Box(modifier = Modifier.weight(1f)) {
                        PontosApoioButton(
                            action = ::setPontosApoioScreen,
                            localizationViewModel = localizationViewModel
                        )
                    }
                }
            }

            item(key = "botoes_finais") {
                BotoesFinaisView(
                    onUnidadesSaudeClick = ::setUnidadesSaudeScreen,
                    onPontosTuristicosClick = ::setPontosTuristicosScreen,
                    onInterdicoesClick = ::setInterdicoesScreen,
                    localizationViewModel = localizationViewModel,
                )
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
            // Usar dados locais em vez do ViewModel
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
                localizationViewModel = localizationViewModel
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
// Função para dados de exemplo dos pontos turísticos
private fun getExemplosPontosTuristicos(): List<PontoTuristico> {
    return listOf(
        // PATRIMÔNIO
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
                pt = "Uma das sete maravilhas do mundo moderno, o Cristo Redentor é o cartão postal mais famoso do Rio de Janeiro. A estátua art déco de Jesus Cristo fica no topo do Corcovado, a 709 metros de altitude.",
                en = "One of the seven wonders of the modern world, Christ the Redeemer is Rio de Janeiro's most famous postcard. The art deco statue of Jesus Christ sits atop Corcovado mountain at 709 meters altitude.",
                es = "Una de las siete maravillas del mundo moderno, el Cristo Redentor es la postal más famosa de Río de Janeiro. La estatua art déco de Jesucristo se encuentra en la cima del Corcovado, a 709 metros de altitud.",
                fr = "L'une des sept merveilles du monde moderne, le Christ Rédempteur est la carte postale la plus célèbre de Rio de Janeiro. La statue art déco de Jésus-Christ se trouve au sommet du Corcovado, à 709 mètres d'altitude.",
                zh = "作为现代世界七大奇迹之一，救世基督像是里约热内卢最著名的地标。这座装饰艺术风格的耶稣基督雕像坐落在科尔科瓦多山顶，海拔709米。"
            ),
            endereco = "Parque Nacional da Tijuca - Alto da Boa Vista, Rio de Janeiro",
            telefone = "(21) 2558-1329",
            website = "https://cristoredentoroficial.com.br",
            coordenadas = LatLng(-22.9519, -43.2105),
            avaliacao = 4.8f
        ),

        PontoTuristico(
            id = "2",
            nomeLocalizado = LocalizedText(
                pt = "Escadaria Selarón",
                en = "Selarón Steps",
                es = "Escalera de Selarón",
                fr = "Escalier Selarón",
                zh = "塞勒隆阶梯"
            ),
            categoria = CategoriaPonto.PATRIMONIO,
            textoLocalizado = LocalizedText(
                pt = "Obra do artista chileno Jorge Selarón, a escadaria conecta os bairros da Lapa e Santa Teresa com seus 215 degraus cobertos por mais de 2000 azulejos de mais de 60 países.",
                en = "Created by Chilean artist Jorge Selarón, the stairway connects the Lapa and Santa Teresa neighborhoods with its 215 steps covered by over 2000 tiles from more than 60 countries.",
                es = "Obra del artista chileno Jorge Selarón, la escalera conecta los barrios de Lapa y Santa Teresa con sus 215 peldaños cubiertos por más de 2000 azulejos de más de 60 países.",
                fr = "Œuvre de l'artiste chilien Jorge Selarón, l'escalier relie les quartiers de Lapa et Santa Teresa avec ses 215 marches couvertes de plus de 2000 carreaux de plus de 60 pays.",
                zh = "由智利艺术家豪尔赫·塞拉隆创作，这个阶梯连接了拉帕和圣特雷莎社区，215级台阶上覆盖着来自60多个国家的2000多块瓷砖。"
            ),
            endereco = "R. Joaquim Silva, S/N - Lapa, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9152, -43.1795),
            avaliacao = 4.6f
        ),

        PontoTuristico(
            id = "3",
            nomeLocalizado = LocalizedText(
                pt = "Theatro Municipal",
                en = "Municipal Theater",
                es = "Teatro Municipal",
                fr = "Théâtre Municipal",
                zh = "市立剧院"
            ),
            categoria = CategoriaPonto.PATRIMONIO,
            textoLocalizado = LocalizedText(
                pt = "Inaugurado em 1909, é um dos mais importantes teatros do Brasil e um dos mais belos exemplares da arquitetura eclética do país. Inspirado na Ópera de Paris.",
                en = "Opened in 1909, it is one of Brazil's most important theaters and one of the most beautiful examples of eclectic architecture in the country. Inspired by the Paris Opera.",
                es = "Inaugurado en 1909, es uno de los teatros más importantes de Brasil y uno de los más bellos ejemplares de la arquitectura ecléctica del país. Inspirado en la Ópera de París.",
                fr = "Inauguré en 1909, c'est l'un des théâtres les plus importants du Brésil et l'un des plus beaux exemples d'architecture éclectique du pays. Inspiré de l'Opéra de Paris.",
                zh = "建于1909年，是巴西最重要的剧院之一，也是该国折衷主义建筑最美丽的典范之一。灵感来自巴黎歌剧院。"
            ),
            endereco = "Praça Floriano, S/N - Centro, Rio de Janeiro",
            telefone = "(21) 2332-9191",
            website = "https://theatromunicipal.rj.gov.br",
            coordenadas = LatLng(-22.9090, -43.1765),
            avaliacao = 4.7f
        ),

        PontoTuristico(
            id = "4",
            nomeLocalizado = LocalizedText(
                pt = "Real Gabinete Português de Leitura",
                en = "Royal Portuguese Reading Room",
                es = "Real Gabinete Portugués de Lectura",
                fr = "Cabinet Royal Portugais de Lecture",
                zh = "皇家葡萄牙语阅览室"
            ),
            categoria = CategoriaPonto.BIBLIOTECA,
            textoLocalizado = LocalizedText(
                pt = "Considerada uma das mais belas bibliotecas do mundo, abriga a maior coleção de literatura portuguesa fora de Portugal, com mais de 350 mil volumes.",
                en = "Considered one of the most beautiful libraries in the world, it houses the largest collection of Portuguese literature outside Portugal, with over 350,000 volumes.",
                es = "Considerada una de las bibliotecas más bellas del mundo, alberga la mayor colección de literatura portuguesa fuera de Portugal, con más de 350 mil volúmenes.",
                fr = "Considérée comme l'une des plus belles bibliothèques du monde, elle abrite la plus grande collection de littérature portugaise hors du Portugal, avec plus de 350 000 volumes.",
                zh = "被认为是世界上最美丽的图书馆之一，收藏着葡萄牙以外最大的葡萄牙文学作品集，拥有超过35万册藏书。"
            ),
            endereco = "R. Luís de Camões, 30 - Centro, Rio de Janeiro",
            telefone = "(21) 2221-3138",
            website = "https://realgabinete.com.br",
            coordenadas = LatLng(-22.9035, -43.1809),
            avaliacao = 4.8f
        ),

        // PRAIAS
        PontoTuristico(
            id = "5",
            nomeLocalizado = LocalizedText(
                pt = "Praia de Copacabana",
                en = "Copacabana Beach",
                es = "Playa de Copacabana",
                fr = "Plage de Copacabana",
                zh = "科帕卡巴纳海滩"
            ),
            categoria = CategoriaPonto.PRAIA,
            textoLocalizado = LocalizedText(
                pt = "Uma das praias mais famosas do mundo, com 4 km de extensão e o icônico calçadão de pedras portuguesas em ondas preto e branco. Palco do Réveillon mais famoso do Brasil.",
                en = "One of the world's most famous beaches, 4 km long with the iconic Portuguese stone sidewalk in black and white waves. Stage of Brazil's most famous New Year's Eve celebration.",
                es = "Una de las playas más famosas del mundo, con 4 km de extensión y el icónico paseo de piedras portuguesas en ondas blanco y negro. Escenario del Año Nuevo más famoso de Brasil.",
                fr = "L'une des plages les plus célèbres du monde, longue de 4 km avec l'emblématique trottoir en pavés portugais aux vagues noires et blanches. Scène de la plus célèbre célébration du Nouvel An au Brésil.",
                zh = "世界上最著名的海滩之一，长达4公里，拥有标志性的黑白波浪图案葡萄牙石人行道。巴西最著名的新年庆祝活动举办地。"
            ),
            endereco = "Av. Atlântica - Copacabana, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9711, -43.1822),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "6",
            nomeLocalizado = LocalizedText(
                pt = "Praia de Ipanema",
                en = "Ipanema Beach",
                es = "Playa de Ipanema",
                fr = "Plage d'Ipanema",
                zh = "伊帕内玛海滩"
            ),
            categoria = CategoriaPonto.PRAIA,
            textoLocalizado = LocalizedText(
                pt = "Imortalizada pela música 'Garota de Ipanema', é point da elite carioca. Dividida em postos, cada um com seu público específico: Posto 9 é famoso pela diversidade.",
                en = "Immortalized by the song 'Girl from Ipanema', it's a hotspot for Rio's elite. Divided into posts, each with its specific crowd: Post 9 is famous for diversity.",
                es = "Inmortalizada por la canción 'Chica de Ipanema', es punto de encuentro de la élite carioca. Dividida en puestos, cada uno con su público específico: Puesto 9 es famoso por la diversidad.",
                fr = "Immortalisée par la chanson 'La Fille d'Ipanema', c'est le point de rencontre de l'élite de Rio. Divisée en postes, chacun avec son public spécifique: le Poste 9 est célèbre pour sa diversité.",
                zh = "因歌曲《伊帕内玛女孩》而闻名，是里约精英的聚集地。分为不同的区域，每个区域都有特定的人群：9号哨所以多样性而闻名。"
            ),
            endereco = "Av. Vieira Souto - Ipanema, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9839, -43.2045),
            avaliacao = 4.7f
        ),

        PontoTuristico(
            id = "7",
            nomeLocalizado = LocalizedText(
                pt = "Praia do Arpoador",
                en = "Arpoador Beach",
                es = "Playa del Arpoador",
                fr = "Plage d'Arpoador",
                zh = "阿尔波阿多海滩"
            ),
            categoria = CategoriaPonto.PRAIA,
            textoLocalizado = LocalizedText(
                pt = "Pequena praia entre Ipanema e Copacabana, famosa pelo pôr do sol aplaudido diariamente. Point de surfistas e pescadores, com vista privilegiada para o Dois Irmãos.",
                en = "Small beach between Ipanema and Copacabana, famous for the daily applauded sunset. Surfers and fishermen's spot, with privileged view of Dois Irmãos.",
                es = "Pequeña playa entre Ipanema y Copacabana, famosa por la puesta de sol aplaudida diariamente. Punto de surfistas y pescadores, con vista privilegiada a los Dois Irmãos.",
                fr = "Petite plage entre Ipanema et Copacabana, célèbre pour le coucher de soleil applaudi quotidiennement. Spot de surfeurs et pêcheurs, avec vue privilégiée sur les Dois Irmãos.",
                zh = "位于伊帕内玛和科帕卡巴纳之间的小海滩，以每日受到掌声欢迎的日落而闻名。冲浪者和渔民的聚集地，可以欣赏到两兄弟山的美景。"
            ),
            endereco = "Entre Copacabana e Ipanema, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9889, -43.1930),
            avaliacao = 4.8f
        ),

        PontoTuristico(
            id = "8",
            nomeLocalizado = LocalizedText(
                pt = "Praia da Barra da Tijuca",
                en = "Barra da Tijuca Beach",
                es = "Playa de Barra da Tijuca",
                fr = "Plage de Barra da Tijuca",
                zh = "巴拉达蒂茹卡海滩"
            ),
            categoria = CategoriaPonto.PRAIA,
            textoLocalizado = LocalizedText(
                pt = "A maior praia do Rio com 18 km de extensão. Águas limpas e frias, ideal para esportes aquáticos. Conhecida pelos quiosques modernos e vida noturna agitada.",
                en = "Rio's longest beach with 18 km of extension. Clean and cold waters, ideal for water sports. Known for modern kiosks and vibrant nightlife.",
                es = "La playa más grande de Río con 18 km de extensión. Aguas limpias y frías, ideal para deportes acuáticos. Conocida por los quioscos modernos y vida nocturna agitada.",
                fr = "La plus longue plage de Rio avec 18 km d'extension. Eaux propres et froides, idéales pour les sports nautiques. Connue pour ses kiosques modernes et sa vie nocturne animée.",
                zh = "里约最长的海滩，延伸18公里。清澈寒冷的海水，非常适合水上运动。以现代化的售货亭和充满活力的夜生活而闻名。"
            ),
            endereco = "Av. do Pepê - Barra da Tijuca, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-23.0126, -43.3219),
            avaliacao = 4.4f
        ),

        // PARQUES
        PontoTuristico(
            id = "9",
            nomeLocalizado = LocalizedText(
                pt = "Jardim Botânico",
                en = "Botanical Garden",
                es = "Jardín Botánico",
                fr = "Jardin Botanique",
                zh = "植物园"
            ),
            categoria = CategoriaPonto.PARQUE,
            textoLocalizado = LocalizedText(
                pt = "Fundado em 1808 por D. João VI, possui mais de 6.500 espécies de plantas. Destaque para as palmeiras imperiais, vitórias-régias e o orquidário com 700 espécies.",
                en = "Founded in 1808 by King João VI, it has over 6,500 plant species. Highlights include imperial palm trees, giant water lilies and the orchid garden with 700 species.",
                es = "Fundado en 1808 por D. João VI, posee más de 6.500 especies de plantas. Destaque para las palmeras imperiales, victorias regias y el orquideario con 700 especies.",
                fr = "Fondé en 1808 par D. João VI, il possède plus de 6 500 espèces de plantes. Points forts: les palmiers impériaux, les nénuphars géants et l'orchidarium avec 700 espèces.",
                zh = "由若昂六世于1808年建立，拥有超过6500种植物。亮点包括帝王棕榈树、王莲和拥有700种兰花的兰花园。"
            ),
            endereco = "R. Jardim Botânico, 1008 - Jardim Botânico, Rio de Janeiro",
            telefone = "(21) 3874-1808",
            website = "https://jbrj.gov.br",
            coordenadas = LatLng(-22.9674, -43.2239),
            avaliacao = 4.6f
        ),

        PontoTuristico(
            id = "10",
            nomeLocalizado = LocalizedText(
                pt = "Parque Lage",
                en = "Lage Park",
                es = "Parque Lage",
                fr = "Parc Lage",
                zh = "拉赫公园"
            ),
            categoria = CategoriaPonto.PARQUE,
            textoLocalizado = LocalizedText(
                pt = "Palacete do século XX aos pés do Corcovado, cercado por jardins românticos. Abriga a Escola de Artes Visuais e um café charmoso com vista para o Cristo.",
                en = "20th century mansion at the foot of Corcovado, surrounded by romantic gardens. Houses the Visual Arts School and a charming café with views of Christ statue.",
                es = "Palacete del siglo XX a los pies del Corcovado, rodeado por jardines románticos. Alberga la Escuela de Artes Visuales y un café encantador con vista al Cristo.",
                fr = "Petit palais du XXe siècle au pied du Corcovado, entouré de jardins romantiques. Abrite l'École des Arts Visuels et un charmant café avec vue sur le Christ.",
                zh = "20世纪的宫殿位于科尔科瓦多山脚下，被浪漫的花园环绕。设有视觉艺术学校和一家迷人的咖啡馆，可以欣赏到基督像的景色。"
            ),
            endereco = "R. Jardim Botânico, 414 - Jardim Botânico, Rio de Janeiro",
            telefone = "(21) 2334-4088",
            website = null,
            coordenadas = LatLng(-22.9618, -43.2111),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "11",
            nomeLocalizado = LocalizedText(
                pt = "Parque Nacional da Tijuca",
                en = "Tijuca National Park",
                es = "Parque Nacional de Tijuca",
                fr = "Parc National de Tijuca",
                zh = "蒂茹卡国家公园"
            ),
            categoria = CategoriaPonto.PARQUE,
            textoLocalizado = LocalizedText(
                pt = "Uma das maiores florestas urbanas do mundo, com trilhas, cachoeiras e mirantes. Inclui o Corcovado, a Pedra da Gávea e o Pico da Tijuca, ponto mais alto da cidade.",
                en = "One of the world's largest urban forests, with trails, waterfalls and viewpoints. Includes Corcovado, Pedra da Gávea and Pico da Tijuca, the city's highest point.",
                es = "Una de las mayores florestas urbanas del mundo, con senderos, cascadas y miradores. Incluye el Corcovado, la Pedra da Gávea y el Pico da Tijuca, punto más alto de la ciudad.",
                fr = "L'une des plus grandes forêts urbaines du monde, avec des sentiers, des cascades et des points de vue. Comprend le Corcovado, Pedra da Gávea et Pico da Tijuca, le point culminant de la ville.",
                zh = "世界上最大的城市森林之一，有步道、瀑布和观景点。包括科尔科瓦多山、加维亚岩石和蒂茹卡峰——城市的最高点。"
            ),
            endereco = "Estrada da Cascatinha, 850 - Alto da Boa Vista, Rio de Janeiro",
            telefone = "(21) 2492-2253",
            website = "https://parquenacionaldatijuca.rio",
            coordenadas = LatLng(-22.9494, -43.2839),
            avaliacao = 4.7f
        ),

        // MUSEUS
        PontoTuristico(
            id = "12",
            nomeLocalizado = LocalizedText(
                pt = "Museu do Amanhã",
                en = "Museum of Tomorrow",
                es = "Museo del Mañana",
                fr = "Musée de Demain",
                zh = "明日博物馆"
            ),
            categoria = CategoriaPonto.MUSEU,
            textoLocalizado = LocalizedText(
                pt = "Museu de ciências projetado por Santiago Calatrava. Explora possibilidades de futuro sustentável através de exposições interativas sobre cosmos, terra, antropoceno e amanhã.",
                en = "Science museum designed by Santiago Calatrava. Explores possibilities for a sustainable future through interactive exhibitions about cosmos, earth, anthropocene and tomorrow.",
                es = "Museo de ciencias diseñado por Santiago Calatrava. Explora posibilidades de futuro sostenible a través de exposiciones interactivas sobre cosmos, tierra, antropoceno y mañana.",
                fr = "Musée des sciences conçu par Santiago Calatrava. Explore les possibilités d'un avenir durable à travers des expositions interactives sur le cosmos, la terre, l'anthropocène et demain.",
                zh = "由圣地亚哥·卡拉特拉瓦设计的科学博物馆。通过关于宇宙、地球、人类世和未来的互动展览，探索可持续未来的可能性。"
            ),
            endereco = "Praça Mauá, 1 - Centro, Rio de Janeiro",
            telefone = "(21) 3812-1800",
            website = "https://museudoamanha.org.br",
            coordenadas = LatLng(-22.8945, -43.1809),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "13",
            nomeLocalizado = LocalizedText(
                pt = "Museu de Arte do Rio (MAR)",
                en = "Rio Art Museum (MAR)",
                es = "Museo de Arte de Río (MAR)",
                fr = "Musée d'Art de Rio (MAR)",
                zh = "里约艺术博物馆"
            ),
            categoria = CategoriaPonto.MUSEU,
            textoLocalizado = LocalizedText(
                pt = "Dedicado à arte e cultura visual do Rio. Ocupa dois prédios interligados: o Palacete Dom João VI e o edifício modernista. Vista panorâmica da Baía de Guanabara.",
                en = "Dedicated to Rio's art and visual culture. Occupies two interconnected buildings: Dom João VI Palace and the modernist building. Panoramic view of Guanabara Bay.",
                es = "Dedicado al arte y cultura visual de Río. Ocupa dos edificios interconectados: el Palacete Dom João VI y el edificio modernista. Vista panorámica de la Bahía de Guanabara.",
                fr = "Dédié à l'art et à la culture visuelle de Rio. Occupe deux bâtiments interconnectés: le Palais Dom João VI et le bâtiment moderniste. Vue panoramique sur la baie de Guanabara.",
                zh = "致力于里约的艺术和视觉文化。占据两座相互连接的建筑：若昂六世宫殿和现代主义建筑。瓜纳巴拉湾的全景。"
            ),
            endereco = "Praça Mauá, 5 - Centro, Rio de Janeiro",
            telefone = "(21) 3031-2741",
            website = "https://museudeartedorio.org.br",
            coordenadas = LatLng(-22.8966, -43.1807),
            avaliacao = 4.4f
        ),

        PontoTuristico(
            id = "14",
            nomeLocalizado = LocalizedText(
                pt = "Museu Nacional de Belas Artes",
                en = "National Museum of Fine Arts",
                es = "Museo Nacional de Bellas Artes",
                fr = "Musée National des Beaux-Arts",
                zh = "国家美术博物馆"
            ),
            categoria = CategoriaPonto.MUSEU,
            textoLocalizado = LocalizedText(
                pt = "Principal museu de arte do Brasil, com acervo de 70 mil peças. Destaque para a coleção de arte brasileira do século XIX e obras de Portinari, Di Cavalcanti e Tarsila.",
                en = "Brazil's main art museum, with a collection of 70,000 pieces. Highlights include the 19th century Brazilian art collection and works by Portinari, Di Cavalcanti and Tarsila.",
                es = "Principal museo de arte de Brasil, con colección de 70 mil piezas. Destaque para la colección de arte brasileño del siglo XIX y obras de Portinari, Di Cavalcanti y Tarsila.",
                fr = "Principal musée d'art du Brésil, avec une collection de 70 000 pièces. Points forts: la collection d'art brésilien du XIXe siècle et les œuvres de Portinari, Di Cavalcanti et Tarsila.",
                zh = "巴西主要的艺术博物馆，收藏了7万件作品。亮点包括19世纪的巴西艺术收藏以及波蒂纳里、迪·卡瓦尔坎蒂和塔西拉的作品。"
            ),
            endereco = "Av. Rio Branco, 199 - Centro, Rio de Janeiro",
            telefone = "(21) 2240-0068",
            website = "https://mnba.gov.br",
            coordenadas = LatLng(-22.9094, -43.1751),
            avaliacao = 4.3f
        ),

        // CULTURA
        PontoTuristico(
            id = "15",
            nomeLocalizado = LocalizedText(
                pt = "Lapa e Arcos da Lapa",
                en = "Lapa and Lapa Arches",
                es = "Lapa y Arcos de Lapa",
                fr = "Lapa et Arcs de Lapa",
                zh = "拉帕区和拉帕拱门"
            ),
            categoria = CategoriaPonto.CULTURA,
            textoLocalizado = LocalizedText(
                pt = "Antigo aqueduto colonial, hoje símbolo da boemia carioca. A região é conhecida pela vida noturna, samba, bares históricos e a famosa Escadaria Selarón.",
                en = "Former colonial aqueduct, now symbol of Rio's bohemian life. The region is known for nightlife, samba, historic bars and the famous Selarón Steps.",
                es = "Antiguo acueducto colonial, hoy símbolo de la bohemia carioca. La región es conocida por la vida nocturna, samba, bares históricos y la famosa Escalera Selarón.",
                fr = "Ancien aqueduc colonial, aujourd'hui symbole de la vie bohème de Rio. La région est connue pour sa vie nocturne, la samba, les bars historiques et le célèbre Escalier Selarón.",
                zh = "前殖民地水渠，现在是里约波西米亚生活的象征。该地区以夜生活、桑巴舞、历史悠久的酒吧和著名的塞勒隆阶梯而闻名。"
            ),
            endereco = "Largo da Lapa - Centro, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9134, -43.1803),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "16",
            nomeLocalizado = LocalizedText(
                pt = "Centro Cultural Banco do Brasil",
                en = "Bank of Brazil Cultural Center",
                es = "Centro Cultural Banco de Brasil",
                fr = "Centre Culturel Banco do Brasil",
                zh = "巴西银行文化中心"
            ),
            categoria = CategoriaPonto.CULTURA,
            textoLocalizado = LocalizedText(
                pt = "Um dos centros culturais mais visitados do mundo. Prédio histórico de 1906 que abriga exposições, teatro, cinema e música. Arquitetura neoclássica preservada.",
                en = "One of the world's most visited cultural centers. Historic 1906 building housing exhibitions, theater, cinema and music. Preserved neoclassical architecture.",
                es = "Uno de los centros culturales más visitados del mundo. Edificio histórico de 1906 que alberga exposiciones, teatro, cine y música. Arquitectura neoclásica preservada.",
                fr = "L'un des centres culturels les plus visités au monde. Bâtiment historique de 1906 abritant expositions, théâtre, cinéma et musique. Architecture néoclassique préservée.",
                zh = "世界上参观人数最多的文化中心之一。1906年的历史建筑，举办展览、戏剧、电影和音乐活动。保存完好的新古典主义建筑。"
            ),
            endereco = "R. Primeiro de Março, 66 - Centro, Rio de Janeiro",
            telefone = "(21) 3808-2020",
            website = "https://ccbb.com.br/rio-de-janeiro",
            coordenadas = LatLng(-22.9027, -43.1763),
            avaliacao = 4.6f
        ),

        PontoTuristico(
            id = "17",
            nomeLocalizado = LocalizedText(
                pt = "Feira de São Cristóvão",
                en = "São Cristóvão Fair",
                es = "Feria de São Cristóvão",
                fr = "Foire de São Cristóvão",
                zh = "圣克里斯托旺集市"
            ),
            categoria = CategoriaPonto.CULTURA,
            textoLocalizado = LocalizedText(
                pt = "Centro de tradições nordestinas no Rio. Mais de 700 barracas com artesanato, comidas típicas e shows de forró. Funciona como uma mini cidade nordestina.",
                en = "Center of Northeastern traditions in Rio. Over 700 stalls with handicrafts, typical foods and forró shows. Works as a mini Northeastern city.",
                es = "Centro de tradiciones nordestinas en Río. Más de 700 puestos con artesanía, comidas típicas y shows de forró. Funciona como una mini ciudad nordestina.",
                fr = "Centre des traditions du Nord-Est à Rio. Plus de 700 stands avec artisanat, plats typiques et spectacles de forró. Fonctionne comme une mini-ville du Nord-Est.",
                zh = "里约的东北传统中心。超过700个摊位，出售手工艺品、特色食品并举办福鸥舞表演。就像一个迷你的东北城市。"
            ),
            endereco = "Campo de São Cristóvão, S/N - São Cristóvão, Rio de Janeiro",
            telefone = "(21) 2580-5335",
            website = "https://feiradesaocristovao.org.br",
            coordenadas = LatLng(-22.8965, -43.2227),
            avaliacao = 4.4f
        ),

        // ESPORTE
        PontoTuristico(
            id = "18",
            nomeLocalizado = LocalizedText(
                pt = "Estádio do Maracanã",
                en = "Maracanã Stadium",
                es = "Estadio Maracanã",
                fr = "Stade Maracanã",
                zh = "马拉卡纳体育场"
            ),
            categoria = CategoriaPonto.ESPORTE,
            textoLocalizado = LocalizedText(
                pt = "Um dos templos do futebol mundial, palco de duas finais de Copa do Mundo. Reformado para a Copa de 2014, oferece tours guiados pelo museu e áreas internas.",
                en = "One of the world's football temples, stage of two World Cup finals. Renovated for the 2014 World Cup, offers guided tours through the museum and internal areas.",
                es = "Uno de los templos del fútbol mundial, escenario de dos finales de Copa del Mundo. Reformado para la Copa de 2014, ofrece tours guiados por el museo y áreas internas.",
                fr = "L'un des temples du football mondial, théâtre de deux finales de Coupe du Monde. Rénové pour la Coupe du Monde 2014, propose des visites guidées du musée et des espaces intérieurs.",
                zh = "世界足球圣殿之一，两届世界杯决赛的举办地。为2014年世界杯而翻新，提供博物馆和内部区域的导览服务。"
            ),
            endereco = "Av. Pres. Castelo Branco, Portão 3 - Maracanã, Rio de Janeiro",
            telefone = "(21) 2334-1705",
            website = "https://www.estadiodomaracana.com.br",
            coordenadas = LatLng(-22.9121, -43.2302),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "19",
            nomeLocalizado = LocalizedText(
                pt = "Estádio Nilton Santos (Engenhão)",
                en = "Nilton Santos Stadium",
                es = "Estadio Nilton Santos",
                fr = "Stade Nilton Santos",
                zh = "尼尔顿·桑托斯体育场"
            ),
            categoria = CategoriaPonto.ESPORTE,
            textoLocalizado = LocalizedText(
                pt = "Estádio olímpico do Rio, casa do Botafogo. Palco do atletismo nas Olimpíadas 2016. Capacidade para 46 mil pessoas e pista de atletismo de padrão internacional.",
                en = "Rio's Olympic stadium, home of Botafogo. Athletics venue for 2016 Olympics. Capacity for 46,000 people and international standard athletics track.",
                es = "Estadio olímpico de Río, casa del Botafogo. Escenario del atletismo en las Olimpiadas 2016. Capacidad para 46 mil personas y pista de atletismo de estándar internacional.",
                fr = "Stade olympique de Rio, domicile de Botafogo. Site d'athlétisme des JO 2016. Capacité de 46 000 personnes et piste d'athlétisme aux normes internationales.",
                zh = "里约奥林匹克体育场，博塔弗戈队的主场。2016年奥运会田径比赛场地。可容纳4.6万人，拥有国际标准田径跑道。"
            ),
            endereco = "R. José dos Reis, 425 - Engenho de Dentro, Rio de Janeiro",
            telefone = "(21) 3433-0788",
            website = null,
            coordenadas = LatLng(-22.8930, -43.2923),
            avaliacao = 4.3f
        ),

        PontoTuristico(
            id = "20",
            nomeLocalizado = LocalizedText(
                pt = "Marina da Glória",
                en = "Gloria Marina",
                es = "Marina de Gloria",
                fr = "Marina de Gloria",
                zh = "格洛里亚码头"
            ),
            categoria = CategoriaPonto.ESPORTE,
            textoLocalizado = LocalizedText(
                pt = "Principal marina pública do Rio. Base das competições de vela nas Olimpíadas. Escola de vela, aluguel de barcos e vista privilegiada do Pão de Açúcar.",
                en = "Rio's main public marina. Sailing competition base for the Olympics. Sailing school, boat rental and privileged view of Sugar Loaf.",
                es = "Principal marina pública de Río. Base de las competiciones de vela en las Olimpiadas. Escuela de vela, alquiler de barcos y vista privilegiada del Pan de Azúcar.",
                fr = "Principal port de plaisance public de Rio. Base des compétitions de voile aux JO. École de voile, location de bateaux et vue privilégiée sur le Pain de Sucre.",
                zh = "里约主要的公共码头。奥运会帆船比赛基地。帆船学校、船只租赁和糖面包山的优越景观。"
            ),
            endereco = "Av. Infante Dom Henrique, S/N - Glória, Rio de Janeiro",
            telefone = "(21) 2555-2200",
            website = "http://www.marinadagloria.com.br",
            coordenadas = LatLng(-22.9198, -43.1689),
            avaliacao = 4.2f
        ),

        // ARTE
        PontoTuristico(
            id = "21",
            nomeLocalizado = LocalizedText(
                pt = "Museu de Arte Moderna (MAM)",
                en = "Modern Art Museum (MAM)",
                es = "Museo de Arte Moderno (MAM)",
                fr = "Musée d'Art Moderne (MAM)",
                zh = "现代艺术博物馆"
            ),
            categoria = CategoriaPonto.ARTE,
            textoLocalizado = LocalizedText(
                pt = "Projeto arquitetônico de Affonso Eduardo Reidy, é referência em arte moderna e contemporânea. Jardins de Burle Marx e vista para a Baía de Guanabara.",
                en = "Architectural project by Affonso Eduardo Reidy, reference in modern and contemporary art. Gardens by Burle Marx and view of Guanabara Bay.",
                es = "Proyecto arquitectónico de Affonso Eduardo Reidy, es referencia en arte moderno y contemporáneo. Jardines de Burle Marx y vista a la Bahía de Guanabara.",
                fr = "Projet architectural d'Affonso Eduardo Reidy, référence en art moderne et contemporain. Jardins de Burle Marx et vue sur la baie de Guanabara.",
                zh = "阿方索·爱德华多·雷迪的建筑项目，是现代和当代艺术的参考。布尔勒·马克思的花园和瓜纳巴拉湾的景色。"
            ),
            endereco = "Av. Infante Dom Henrique, 85 - Parque do Flamengo, Rio de Janeiro",
            telefone = "(21) 3883-5600",
            website = "http://www.mam.rio",
            coordenadas = LatLng(-22.9186, -43.1718),
            avaliacao = 4.4f
        ),

        PontoTuristico(
            id = "22",
            nomeLocalizado = LocalizedText(
                pt = "Instituto Moreira Salles",
                en = "Moreira Salles Institute",
                es = "Instituto Moreira Salles",
                fr = "Institut Moreira Salles",
                zh = "莫雷拉·萨莱斯研究所"
            ),
            categoria = CategoriaPonto.ARTE,
            textoLocalizado = LocalizedText(
                pt = "Casa modernista com jardins de Burle Marx. Importante acervo de fotografia, música, literatura e iconografia brasileira. Exposições e atividades culturais.",
                en = "Modernist house with gardens by Burle Marx. Important collection of photography, music, literature and Brazilian iconography. Exhibitions and cultural activities.",
                es = "Casa modernista con jardines de Burle Marx. Importante acervo de fotografía, música, literatura e iconografía brasileña. Exposiciones y actividades culturales.",
                fr = "Maison moderniste avec jardins de Burle Marx. Important fonds de photographie, musique, littérature et iconographie brésilienne. Expositions et activités culturelles.",
                zh = "拥有布尔勒·马克思花园的现代主义住宅。重要的摄影、音乐、文学和巴西图像学收藏。展览和文化活动。"
            ),
            endereco = "R. Marquês de São Vicente, 476 - Gávea, Rio de Janeiro",
            telefone = "(21) 3284-7400",
            website = "https://ims.com.br",
            coordenadas = LatLng(-22.9830, -43.2311),
            avaliacao = 4.7f
        ),

        PontoTuristico(
            id = "23",
            nomeLocalizado = LocalizedText(
                pt = "Cidade das Artes",
                en = "City of Arts",
                es = "Ciudad de las Artes",
                fr = "Cité des Arts",
                zh = "艺术之城"
            ),
            categoria = CategoriaPonto.ARTE,
            textoLocalizado = LocalizedText(
                pt = "Complexo cultural na Barra da Tijuca projetado por Christian de Portzamparc. Sede da Orquestra Sinfônica Brasileira, com salas de concerto, teatro e exposições.",
                en = "Cultural complex in Barra da Tijuca designed by Christian de Portzamparc. Home of the Brazilian Symphony Orchestra, with concert halls, theater and exhibitions.",
                es = "Complejo cultural en Barra da Tijuca diseñado por Christian de Portzamparc. Sede de la Orquesta Sinfónica Brasileña, con salas de concierto, teatro y exposiciones.",
                fr = "Complexe culturel à Barra da Tijuca conçu par Christian de Portzamparc. Siège de l'Orchestre Symphonique Brésilien, avec salles de concert, théâtre et expositions.",
                zh = "由克里斯蒂安·德·波特赞帕克设计的巴拉达蒂茹卡文化综合体。巴西交响乐团所在地，设有音乐厅、剧院和展览厅。"
            ),
            endereco = "Av. das Américas, 5300 - Barra da Tijuca, Rio de Janeiro",
            telefone = "(21) 3325-0102",
            website = "http://www.cidadedasartes.org",
            coordenadas = LatLng(-22.9996, -43.3654),
            avaliacao = 4.5f
        ),

        // MIRANTES
        PontoTuristico(
            id = "24",
            nomeLocalizado = LocalizedText(
                pt = "Pão de Açúcar",
                en = "Sugar Loaf",
                es = "Pan de Azúcar",
                fr = "Pain de Sucre",
                zh = "糖面包山"
            ),
            categoria = CategoriaPonto.MIRANTE,
            textoLocalizado = LocalizedText(
                pt = "Cartão-postal do Rio, o bondinho leva aos 396m do topo. Vista de 360° incluindo praias, Cristo Redentor e Baía de Guanabara. Pôr do sol espetacular.",
                en = "Rio's postcard, the cable car takes you to the 396m summit. 360° view including beaches, Christ the Redeemer and Guanabara Bay. Spectacular sunset.",
                es = "Postal de Río, el teleférico lleva a los 396m de la cima. Vista de 360° incluyendo playas, Cristo Redentor y Bahía de Guanabara. Atardecer espectacular.",
                fr = "Carte postale de Rio, le téléphérique vous emmène au sommet à 396m. Vue à 360° incluant plages, Christ Rédempteur et baie de Guanabara. Coucher de soleil spectaculaire.",
                zh = "里约的明信片，缆车带您到396米的山顶。360度全景，包括海滩、救世基督像和瓜纳巴拉湾。壮观的日落。"
            ),
            endereco = "Av. Pasteur, 520 - Urca, Rio de Janeiro",
            telefone = "(21) 2546-8400",
            website = "https://bondinho.com.br",
            coordenadas = LatLng(-22.9485, -43.1570),
            avaliacao = 4.7f
        ),

        PontoTuristico(
            id = "25",
            nomeLocalizado = LocalizedText(
                pt = "Vista Chinesa",
                en = "Chinese View",
                es = "Vista China",
                fr = "Vue Chinoise",
                zh = "中国亭"
            ),
            categoria = CategoriaPonto.MIRANTE,
            textoLocalizado = LocalizedText(
                pt = "Mirante com pagode chinês construído entre 1902 e 1906. Vista panorâmica da zona sul, Lagoa Rodrigo de Freitas e praias. Acesso por estrada sinuosa na Floresta da Tijuca.",
                en = "Viewpoint with Chinese pagoda built between 1902 and 1906. Panoramic view of the south zone, Rodrigo de Freitas Lagoon and beaches. Access via winding road in Tijuca Forest.",
                es = "Mirador con pagoda china construida entre 1902 y 1906. Vista panorámica de la zona sur, Laguna Rodrigo de Freitas y playas. Acceso por carretera sinuosa en el Bosque de Tijuca.",
                fr = "Point de vue avec pagode chinoise construite entre 1902 et 1906. Vue panoramique sur la zone sud, le lagon Rodrigo de Freitas et les plages. Accès par route sinueuse dans la forêt de Tijuca.",
                zh = "建于1902年至1906年间的中国宝塔观景点。南区、罗德里戈·德·弗雷塔斯湖和海滩的全景。通过蒂茹卡森林的蜿蜒道路进入。"
            ),
            endereco = "Estrada da Vista Chinesa - Alto da Boa Vista, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9599, -43.2231),
            avaliacao = 4.6f
        ),

        PontoTuristico(
            id = "26",
            nomeLocalizado = LocalizedText(
                pt = "Mirante Dona Marta",
                en = "Dona Marta Viewpoint",
                es = "Mirador Dona Marta",
                fr = "Belvédère Dona Marta",
                zh = "多纳·玛尔塔观景台"
            ),
            categoria = CategoriaPonto.MIRANTE,
            textoLocalizado = LocalizedText(
                pt = "A 360m de altitude, oferece vista única do Pão de Açúcar, Cristo Redentor, Lagoa e praias. Heliporto usado em filmagens. Local do clipe 'They Don't Care About Us' de Michael Jackson.",
                en = "At 360m altitude, offers unique view of Sugar Loaf, Christ the Redeemer, Lagoon and beaches. Helipad used in filming. Location of Michael Jackson's 'They Don't Care About Us' video.",
                es = "A 360m de altitud, ofrece vista única del Pan de Azúcar, Cristo Redentor, Laguna y playas. Helipuerto usado en filmaciones. Local del clip 'They Don't Care About Us' de Michael Jackson.",
                fr = "À 360m d'altitude, offre une vue unique sur le Pain de Sucre, le Christ Rédempteur, le Lagon et les plages. Héliport utilisé pour les tournages. Lieu du clip 'They Don't Care About Us' de Michael Jackson.",
                zh = "海拔360米，提供糖面包山、救世基督像、泻湖和海滩的独特景观。用于拍摄的直升机停机坪。迈克尔·杰克逊《They Don't Care About Us》音乐录影带的拍摄地。"
            ),
            endereco = "Estrada Mirante Dona Marta - Cosme Velho, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9439, -43.1967),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "27",
            nomeLocalizado = LocalizedText(
                pt = "Pedra da Gávea",
                en = "Gávea Rock",
                es = "Piedra de Gávea",
                fr = "Pierre de Gávea",
                zh = "加维亚岩石"
            ),
            categoria = CategoriaPonto.MIRANTE,
            textoLocalizado = LocalizedText(
                pt = "Maior bloco de granito à beira-mar do mundo, com 842m. Trilha desafiadora de 3h com trechos de escalaminhada. Vista incomparável de toda a cidade e oceano.",
                en = "World's largest seaside granite block at 842m. Challenging 3-hour trail with climbing sections. Incomparable view of the entire city and ocean.",
                es = "Mayor bloque de granito junto al mar del mundo, con 842m. Sendero desafiante de 3h con tramos de escalada. Vista incomparable de toda la ciudad y océano.",
                fr = "Plus grand bloc de granit en bord de mer au monde, à 842m. Sentier difficile de 3h avec sections d'escalade. Vue incomparable sur toute la ville et l'océan.",
                zh = "世界上最大的海边花岗岩块，高842米。具有挑战性的3小时步道，包含攀爬部分。整个城市和海洋的无与伦比的景色。"
            ),
            endereco = "Entrada pela Estrada da Canoa - São Conrado, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9973, -43.2850),
            avaliacao = 4.9f
        ),

        // PATRIMÔNIO ADICIONAL
        PontoTuristico(
            id = "28",
            nomeLocalizado = LocalizedText(
                pt = "Catedral Metropolitana",
                en = "Metropolitan Cathedral",
                es = "Catedral Metropolitana",
                fr = "Cathédrale Métropolitaine",
                zh = "大都会大教堂"
            ),
            categoria = CategoriaPonto.PATRIMONIO,
            textoLocalizado = LocalizedText(
                pt = "Arquitetura moderna em forma cônica com 75m de altura. Vitrais coloridos de 64m criam ambiente místico. Capacidade para 20 mil pessoas.",
                en = "Modern conical architecture 75m high. 64m colored stained glass windows create a mystical atmosphere. Capacity for 20,000 people.",
                es = "Arquitectura moderna en forma cónica con 75m de altura. Vitrales coloridos de 64m crean ambiente místico. Capacidad para 20 mil personas.",
                fr = "Architecture moderne conique de 75m de haut. Les vitraux colorés de 64m créent une atmosphère mystique. Capacité de 20 000 personnes.",
                zh = "75米高的现代圆锥形建筑。64米高的彩色玻璃窗营造出神秘的氛围。可容纳2万人。"
            ),
            endereco = "Av. República do Chile, 245 - Centro, Rio de Janeiro",
            telefone = "(21) 2240-2669",
            website = null,
            coordenadas = LatLng(-22.9104, -43.1802),
            avaliacao = 4.4f
        ),

        // PRAIAS ADICIONAIS
        PontoTuristico(
            id = "29",
            nomeLocalizado = LocalizedText(
                pt = "Prainha",
                en = "Prainha Beach",
                es = "Playa Prainha",
                fr = "Plage Prainha",
                zh = "小海滩"
            ),
            categoria = CategoriaPonto.PRAIA,
            textoLocalizado = LocalizedText(
                pt = "Praia selvagem e preservada, cercada por morros e vegetação nativa. Águas cristalinas ideais para surf. Uma das praias mais bonitas e menos exploradas do Rio.",
                en = "Wild and preserved beach, surrounded by hills and native vegetation. Crystal clear waters ideal for surfing. One of Rio's most beautiful and less explored beaches.",
                es = "Playa salvaje y preservada, rodeada de cerros y vegetación nativa. Aguas cristalinas ideales para surf. Una de las playas más bonitas y menos exploradas de Río.",
                fr = "Plage sauvage et préservée, entourée de collines et de végétation native. Eaux cristallines idéales pour le surf. L'une des plus belles plages les moins explorées de Rio.",
                zh = "野生且保存完好的海滩，被山丘和原生植被环绕。水晶般清澈的海水非常适合冲浪。里约最美丽且较少被探索的海滩之一。"
            ),
            endereco = "Av. Estado da Guanabara - Recreio dos Bandeirantes, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-23.0407, -43.5047),
            avaliacao = 4.7f
        ),

        PontoTuristico(
            id = "30",
            nomeLocalizado = LocalizedText(
                pt = "Praia do Leblon",
                en = "Leblon Beach",
                es = "Playa de Leblon",
                fr = "Plage de Leblon",
                zh = "莱布隆海滩"
            ),
            categoria = CategoriaPonto.PRAIA,
            textoLocalizado = LocalizedText(
                pt = "Continuação de Ipanema, separada pelo canal do Jardim de Alah. Praia mais exclusiva, frequentada por moradores do bairro nobre. Área kids e quadras esportivas.",
                en = "Continuation of Ipanema, separated by the Jardim de Alah channel. More exclusive beach, frequented by residents of the upscale neighborhood. Kids area and sports courts.",
                es = "Continuación de Ipanema, separada por el canal del Jardim de Alah. Playa más exclusiva, frecuentada por residentes del barrio noble. Área kids y canchas deportivas.",
                fr = "Continuation d'Ipanema, séparée par le canal Jardim de Alah. Plage plus exclusive, fréquentée par les résidents du quartier huppé. Espace enfants et terrains de sport.",
                zh = "伊帕内玛的延伸，由阿拉花园运河分隔。更加独特的海滩，高档社区居民常来此地。设有儿童区和运动场。"
            ),
            endereco = "Av. Delfim Moreira - Leblon, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9867, -43.2242),
            avaliacao = 4.6f
        ),

        // PARQUES ADICIONAIS
        PontoTuristico(
            id = "31",
            nomeLocalizado = LocalizedText(
                pt = "Parque do Flamengo",
                en = "Flamengo Park",
                es = "Parque del Flamengo",
                fr = "Parc du Flamengo",
                zh = "弗拉门戈公园"
            ),
            categoria = CategoriaPonto.PARQUE,
            textoLocalizado = LocalizedText(
                pt = "Maior área de lazer ao ar livre do Rio. Projeto paisagístico de Burle Marx com 1,2 milhão de m². Ciclovia, quadras esportivas, Marina da Glória e MAM.",
                en = "Rio's largest outdoor leisure area. Landscaping project by Burle Marx with 1.2 million m². Bike path, sports courts, Marina da Glória and MAM.",
                es = "Mayor área de ocio al aire libre de Río. Proyecto paisajístico de Burle Marx con 1,2 millones de m². Ciclovía, canchas deportivas, Marina da Glória y MAM.",
                fr = "Plus grande zone de loisirs en plein air de Rio. Projet paysager de Burle Marx avec 1,2 million de m². Piste cyclable, terrains de sport, Marina da Glória et MAM.",
                zh = "里约最大的户外休闲区。由布尔勒·马克思设计的景观项目，占地120万平方米。自行车道、运动场、格洛里亚码头和现代艺术博物馆。"
            ),
            endereco = "Av. Infante Dom Henrique - Flamengo, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9230, -43.1729),
            avaliacao = 4.5f
        ),

        PontoTuristico(
            id = "32",
            nomeLocalizado = LocalizedText(
                pt = "Quinta da Boa Vista",
                en = "Quinta da Boa Vista",
                es = "Quinta da Boa Vista",
                fr = "Quinta da Boa Vista",
                zh = "博阿维斯塔庄园"
            ),
            categoria = CategoriaPonto.PARQUE,
            textoLocalizado = LocalizedText(
                pt = "Antigo jardim imperial, foi residência da família real portuguesa. Abriga o Museu Nacional (em reconstrução) e o Zoológico do Rio. Lagos, grutas e amplas áreas verdes.",
                en = "Former imperial garden, was residence of the Portuguese royal family. Houses the National Museum (under reconstruction) and Rio Zoo. Lakes, caves and wide green areas.",
                es = "Antiguo jardín imperial, fue residencia de la familia real portuguesa. Alberga el Museo Nacional (en reconstrucción) y el Zoológico de Río. Lagos, grutas y amplias áreas verdes.",
                fr = "Ancien jardin impérial, résidence de la famille royale portugaise. Abrite le Musée National (en reconstruction) et le Zoo de Rio. Lacs, grottes et vastes espaces verts.",
                zh = "前帝国花园，曾是葡萄牙王室的住所。设有国家博物馆（重建中）和里约动物园。湖泊、洞穴和广阔的绿地。"
            ),
            endereco = "Av. Pedro II, S/N - São Cristóvão, Rio de Janeiro",
            telefone = null,
            website = null,
            coordenadas = LatLng(-22.9058, -43.2239),
            avaliacao = 4.2f
        )

    )
}

// PERFORMANCE: Função otimizada com cache
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
