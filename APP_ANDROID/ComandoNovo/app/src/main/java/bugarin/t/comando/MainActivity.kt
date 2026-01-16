package bugarin.t.comando

import android.content.pm.ActivityInfo
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.activity.viewModels
import android.content.res.Configuration
import android.util.Log
import androidx.activity.compose.LocalActivityResultRegistryOwner
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import bugarin.t.comando.data.Alerta
import bugarin.t.comando.data.NivelCalor
import bugarin.t.comando.ui.components.FullScreenRadarView
import bugarin.t.comando.ui.components.PermissionHandler
import bugarin.t.comando.ui.screens.*
import bugarin.t.comando.ui.theme.CORTheme
import bugarin.t.comando.ui.utils.rememberLocationPermissionState
import bugarin.t.comando.viewmodel.CORViewModel
import bugarin.t.comando.viewmodel.InterdicoesViewModel
import bugarin.t.comando.viewmodel.LocalizationViewModel
import bugarin.t.comando.viewmodel.ProvideLocalizedContext
import com.google.android.gms.maps.MapsInitializer
import com.google.android.gms.maps.OnMapsSdkInitializedCallback
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.delay

@AndroidEntryPoint
class MainActivity : ComponentActivity(), OnMapsSdkInitializedCallback {

    // Função para controlar a orientação da tela
    private fun setScreenOrientation(orientation: Int) {
        requestedOrientation = orientation
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        MapsInitializer.initialize(this, MapsInitializer.Renderer.LATEST, this)

        setContent {
            val localizationViewModel: LocalizationViewModel = viewModel()
            val corViewModel: CORViewModel = viewModel()
            val interdicoesViewModel: InterdicoesViewModel = viewModel()

            // Garantir que o locale está correto ao iniciar
            LaunchedEffect(Unit) {
                localizationViewModel.refreshLocale()
            }

            // Obter o idioma atual
            val currentLanguage by localizationViewModel.currentLanguage.collectAsStateWithLifecycle()

            // Envolver toda a aplicação com ProvideLocalizedContext
            ProvideLocalizedContext(languageCode = currentLanguage) {
                CORTheme {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        // Fornecer o ActivityResultRegistryOwner para todo o app
                        CompositionLocalProvider(
                            LocalActivityResultRegistryOwner provides this@MainActivity
                        ) {
                            CORApp(
                                corViewModel = corViewModel,
                                localizationViewModel = localizationViewModel,
                                interdicoesViewModel = interdicoesViewModel,
                                onSetOrientation = ::setScreenOrientation // Passa a referência da função
                            )
                        }
                    }
                }
            }
        }
    }

    override fun onMapsSdkInitialized(renderer: MapsInitializer.Renderer) {
        Log.d("MainActivity", "Maps SDK inicializado com renderer: $renderer")
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val localizationViewModel: LocalizationViewModel by viewModels()
        localizationViewModel.refreshLocale()
    }
}

@Composable
fun CORApp(
    corViewModel: CORViewModel,
    localizationViewModel: LocalizationViewModel,
    interdicoesViewModel: InterdicoesViewModel,
    onSetOrientation: (Int) -> Unit // Adiciona o parâmetro
) {
    val navController = rememberNavController()
    val uiState by corViewModel.uiState.collectAsStateWithLifecycle()

    NavHost(
        navController = navController,
        startDestination = "splash"
    ) {
        composable("splash") {
            SplashScreen(
                isLoading = uiState.isLoading,
                hasError = uiState.error != null,
                errorMessage = uiState.error,
                errorType = uiState.errorType,
                isOffline = uiState.isOffline,
                isRetrying = uiState.isRetrying,
                retryCount = uiState.retryCount,
                loadingProgress = uiState.loadingProgress,
                loadingMessage = uiState.loadingMessage,
                onRetry = {
                    corViewModel.retry()
                }
            )

            LaunchedEffect(uiState.isDataLoaded, uiState.error) {
                // Navigate to main screen if:
                // 1. Data is loaded and no error
                // 2. OR we're in offline mode with cached data
                if ((uiState.isDataLoaded && uiState.error == null) ||
                    (uiState.isOffline && uiState.isDataLoaded)) {
                    // Small delay for smooth transition
                    delay(500)
                    navController.navigate("main") {
                        popUpTo("splash") { inclusive = true }
                    }
                }
            }
        }

        composable("main") {
            MainScreen(
                viewModel = corViewModel,
                localizationViewModel = localizationViewModel,
                interdicoesViewModel = interdicoesViewModel,
                navController = navController,
                onNavigateToAlertaDetalhes = { alerta ->
                    // Opção 1: Navegação simplificada (recomendada)
                    navController.navigate("alerta_detalhes/${alerta.id}")
                }
            )
        }

        // Rota simplificada de alerta (recomendada)
        composable(
            route = "alerta_detalhes/{alertaId}",
            arguments = listOf(navArgument("alertaId") { type = NavType.StringType })
        ) { backStackEntry ->
            val alertaId = backStackEntry.arguments?.getString("alertaId")
            val alerta = uiState.alertas.find { it.id == alertaId }

            if (alerta != null) {
                AlertaDetalhesScreen(
                    alerta = alerta,
                    onBack = { navController.popBackStack() },
                    localizationViewModel = localizationViewModel
                )
            }
        }

        // Rota alternativa com parâmetro correto
        composable(
            "alerta_detalhes_full?alertaId={alertaId}&nome={nome}&data={data}&mensagem={mensagem}&geo={geo}&audiourl={audiourl}"
        ) { backStackEntry ->
            val arguments = backStackEntry.arguments

            val alerta = Alerta(
                nome = arguments?.getString("nome")?.ifEmpty { null },
                data = arguments?.getString("data")?.ifEmpty { null },
                mensagem = arguments?.getString("mensagem")?.ifEmpty { null },
                geo = arguments?.getString("geo")?.ifEmpty { null },
                audiourl = arguments?.getString("audiourl")?.ifEmpty { null }
            )

            AlertaDetalhesScreen(
                alerta = alerta,
                onBack = { navController.popBackStack() },
                localizationViewModel = localizationViewModel
            )
        }

        composable("radar_fullscreen") {
            FullScreenRadarView(
                onNavigateBack = { navController.popBackStack() },
                localizationViewModel = localizationViewModel
            )
        }

        // ✅ CORRIGIDO: Rota da câmera com callback correto
        composable(
            route = "camera_detail/{cameraId}",
            arguments = listOf(
                navArgument("cameraId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val cameraId = backStackEntry.arguments?.getString("cameraId") ?: ""

            CameraDetailScreen(
                cameraId = cameraId,
                navController = navController,
                cameraViewModel = corViewModel,
                localizationViewModel = localizationViewModel,
                onSetOrientation = onSetOrientation // ✅ Usa o callback passado como parâmetro
            )
        }

        // Tela de Pontos de Resfriamento
        composable("pontos_resfriamento") {
            PontosResfriamentoScreen(
                pontosUnidadesSaude = uiState.unidadesDeSaude,
                pontosResfriamento = uiState.pontosDeResfriamento,
                nivelCalor = uiState.nivelCalor ?: NivelCalor(),
                recomendacoes = uiState.recomendacoes,
                onBackClick = { navController.popBackStack() },
                localizationViewModel = localizationViewModel
            )
        }

        // Tela de Detalhes de Chuva
        composable("chuva_detalhes") {
            ChuvaDetalhesScreen(
                estacoes = uiState.estacoesChuva,
                onBackClick = { navController.popBackStack() },
                localizationViewModel = localizationViewModel
            )
        }

        // Tela de Detalhes de Vento
        composable("vento_detalhes") {
            VentoDetalhesScreen(
                estacoes = uiState.estacoesMeteorologicas,
                onBackClick = { navController.popBackStack() },
                localizationViewModel = localizationViewModel
            )
        }
    }
}
