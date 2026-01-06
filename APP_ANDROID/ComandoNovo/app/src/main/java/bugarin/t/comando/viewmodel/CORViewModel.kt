package bugarin.t.comando.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import bugarin.t.comando.data.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import java.util.Calendar
import java.util.Date
import javax.inject.Inject

data class CORUiState(
    val isLoading: Boolean = false,
    val isDataLoaded: Boolean = false,
    val currentStage: Int = 1,
    val nomeImagemFundo: String = "dia_claro_p",
    val eventos: List<Evento> = emptyList(),
    val alertas: List<Alerta> = emptyList(),
    val infoTempo: List<InformeTempo> = emptyList(),
    val infoTransito: List<InformeTransito> = emptyList(),
    val cameras: List<Camera> = emptyList(),
    val sirenes: List<Sirene> = emptyList(),
    val pontosDeApoio: List<PontoDeApoio> = emptyList(),
    val unidadesDeSaude: List<PontoDeApoio> = emptyList(),
    val pontosDeResfriamento: List<PontoDeApoio> = emptyList(),
    val nivelCalor: NivelCalor? = null,
    val recomendacoes: List<Recomendacao> = emptyList(),
    // Campos adicionados:
    val estacoesChuva: List<EstacaoChuva> = emptyList(),
    val estacoesMeteorologicas: List<EstacaoMeteorologica> = emptyList(),
    val estacoesCeu: List<EstacaoCeu> = emptyList(),
    val infoSol: List<InfoTempoSol> = emptyList(),
    // Fim dos campos adicionados
    val error: String? = null,
    val errorType: ErrorType? = null,
    val isOffline: Boolean = false,
    val retryCount: Int = 0,
    val isRetrying: Boolean = false,
    val loadingProgress: Float = 0f,
    val loadingMessage: String = "",
    // Novo campo para indicar idioma atual
    val currentLanguage: String = "pt",
)

enum class ErrorType {
    NO_INTERNET,
    TIMEOUT,
    NO_DATA,
    SERVER_ERROR,
    UNKNOWN
}

@HiltViewModel
class CORViewModel @Inject constructor(
    private val repository: CORRepository,
    private val cacheManager: CacheManager,
    // Injeta o LocalizationViewModel
    private val localizationViewModel: LocalizationViewModel
) : ViewModel() {

    companion object {
        private const val TAG = "CORViewModel"
        private const val TIMEOUT_MILLIS = 30000L // 30 segundos
    }

    private val _uiState = MutableStateFlow(CORUiState())
    val uiState: StateFlow<CORUiState> = _uiState.asStateFlow()

    // Armazena o idioma atual para comparação
    private var currentLanguage = "pt"

    init {
        // Carrega dados iniciais
        fetchData()

        // Observa mudanças de idioma
        observeLanguageChanges()
    }

    // ================================
    // OBSERVAÇÃO DE MUDANÇAS DE IDIOMA
    // ================================

    /**
     * Observa mudanças no idioma e recarrega dados automaticamente
     */
    private fun observeLanguageChanges() {
        viewModelScope.launch {
            localizationViewModel.currentLanguage.collect { newLanguage ->
                if (newLanguage != currentLanguage && currentLanguage.isNotEmpty()) {
                    Log.d(TAG, "🌍 Idioma alterado de '$currentLanguage' para '$newLanguage'")
                    currentLanguage = newLanguage

                    // Atualiza o estado para indicar mudança de idioma
                    _uiState.update { it.copy(currentLanguage = newLanguage) }

                    // Recarrega dados específicos do idioma
                    fetchDataForLanguage(newLanguage)
                } else if (currentLanguage.isEmpty()) {
                    // Primeira inicialização
                    currentLanguage = newLanguage
                    _uiState.update { it.copy(currentLanguage = newLanguage) }
                    Log.d(TAG, "🌍 Idioma inicial definido: $newLanguage")
                }
            }
        }
    }

    // ================================
    // MÉTODOS PÚBLICOS
    // ================================

    /**
     * Recarrega todos os dados
     */
    fun fetchData() {
        val language = localizationViewModel.currentLanguage.value
        fetchDataForLanguage(language)
    }

    /**
     * Tenta novamente após erro
     */
    fun retry() {
        Log.d(TAG, "🔁 Tentando novamente...")
        fetchData()
    }

    // ================================
    // MÉTODOS PRIVADOS DE CARREGAMENTO
    // ================================

    /**
     * Função específica para carregar dados de um idioma
     */
    private fun fetchDataForLanguage(languageCode: String) {
        viewModelScope.launch {
            Log.d(TAG, "🚀 Recarregando dados para idioma: $languageCode")

            _uiState.update {
                it.copy(
                    isLoading = true,
                    error = null,
                    errorType = null,
                    isDataLoaded = false,
                    isRetrying = it.retryCount > 0,
                    loadingProgress = 0f,
                    loadingMessage = "Carregando dados em ${getLanguageName(languageCode)}...",
                    currentLanguage = languageCode
                )
            }

            try {
                withTimeout(TIMEOUT_MILLIS) {
                    loadDataInParallelWithLanguage(languageCode)
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro ao carregar dados para idioma: $languageCode", e)
                when (e) {
                    is TimeoutCancellationException -> handleError("Tempo limite excedido. Verifique sua conexão.", ErrorType.TIMEOUT)
                    is UnknownHostException -> handleError("Sem conexão com a internet.", ErrorType.NO_INTERNET)
                    is SocketTimeoutException -> handleError("A conexão está muito lenta.", ErrorType.TIMEOUT)
                    is NoDataException -> handleError(e.message ?: "Nenhum dado disponível.", ErrorType.NO_DATA)
                    else -> handleError("Erro ao carregar dados: ${e.message}", ErrorType.UNKNOWN)
                }
                // Em caso de erro, tenta carregar do cache
                loadFromCacheIfAvailable()
            }
        }
    }

    /**
     * Versão modificada da função original que aceita idioma
     */
    private suspend fun loadDataInParallelWithLanguage(languageCode: String) = coroutineScope {
        Log.d(TAG, "🔄 Iniciando carregamento paralelo para idioma: $languageCode")
        val startTime = System.currentTimeMillis()

        updateProgress(0.1f, "Buscando dados...")

        // Obtém localização do usuário para dados próximos
        val userLocation = localizationViewModel.userLocation.value
        val userLat = userLocation?.latitude
        val userLon = userLocation?.longitude

        // MODIFICADO: Chama métodos com idioma específico
        val deferreds = listOf(
            // Dados específicos do idioma
            async { tryFetch("alertas") { repository.getAlertas(languageCode) } },                    // 0
            async { tryFetch("informes tempo") { repository.getInformesTempo(languageCode) } },        // 1
            async { tryFetch("informes trânsito") { repository.getInformesTransito(languageCode) } },  // 2

            // Dados independentes do idioma (mantém implementação original)
            async { tryFetch("eventos") { repository.getEventos() } },                               // 3
            async { tryFetch("estágio") { repository.getEstagioOperacional() } },                    // 4
            async { tryFetch("câmeras") { repository.getCameras() } },                                // 5
            async { tryFetch("sirenes") {
                if (userLat != null && userLon != null) {
                    repository.getSirenesNearby(userLat, userLon)
                } else {
                    repository.getSirenes()
                }
            }},                                                                                       // 6
            async { tryFetch("pontos apoio") { repository.getPontosApoio() } },                      // 7
            async { tryFetch("unidades saúde") { repository.getUnidadesSaude() } },                  // 8
            async { tryFetch("resfriamento") { repository.getPontosResfriamento() } },               // 9
            async { tryFetch("nível calor") { repository.getNivelCalor() } },                        // 10
            async { tryFetch("recomendações") { repository.getRecomendacoes() } },                   // 11
            async { tryFetch("chuva") { repository.getEstacoesChuva() } },                           // 12
            async { tryFetch("meteorológicas") { repository.getEstacoesMeteorologicas() } },         // 13
            async { tryFetch("céu") { repository.getEstacoesCeu() } },                               // 14
            async { tryFetch("sol") { repository.getInfoSol() } }                                    // 15
        )

        updateProgress(0.8f, "Processando dados...")
        val results = deferreds.awaitAll()

        // Mapeia resultados (com índices corretos)
        val alertas = results[0] as? List<Alerta> ?: emptyList()
        val infoTempo = results[1] as? List<InformeTempo> ?: emptyList()
        val infoTransito = results[2] as? List<InformeTransito> ?: emptyList()
        val eventos = results[3] as? List<Evento> ?: emptyList()
        val estagio = results[4] as? EstagioOperacional
        val cameras = results[5] as? List<Camera> ?: emptyList()
        val sirenes = results[6] as? List<Sirene> ?: emptyList()
        val pontosDeApoio = results[7] as? List<PontoDeApoio> ?: emptyList()
        val unidadesDeSaude = results[8] as? List<PontoDeApoio> ?: emptyList()
        val pontosDeResfriamento = results[9] as? List<PontoDeApoio> ?: emptyList()
        val nivelCalor = results[10] as? NivelCalor
        val recomendacoes = results[11] as? List<Recomendacao> ?: emptyList()
        val estacoesChuva = results[12] as? List<EstacaoChuva> ?: emptyList()
        val estacoesMeteorologicas = results[13] as? List<EstacaoMeteorologica> ?: emptyList()
        val estacoesCeu = results[14] as? List<EstacaoCeu> ?: emptyList()
        val infoSol = results[15] as? List<InfoTempoSol> ?: emptyList()

        updateProgress(0.9f, "Finalizando...")

        val totalDataPoints = listOfNotNull(alertas, eventos, cameras, sirenes, pontosDeApoio, unidadesDeSaude, infoTempo, infoTransito).sumOf { it.size }
        if (totalDataPoints == 0) {
            throw NoDataException("Nenhum dado disponível no momento")
        }

        val nomeImagemFundo = atualizarImagemFundo(estacoesChuva, estacoesCeu, infoSol.firstOrNull())

        val finalState = CORUiState(
            isLoading = false,
            isDataLoaded = true,
            currentStage = estagio?.estagio?.toIntOrNull() ?: 1,
            alertas = alertas,
            infoTempo = infoTempo,
            infoTransito = infoTransito,
            cameras = cameras,
            sirenes = sirenes,
            pontosDeApoio = pontosDeApoio,
            unidadesDeSaude = unidadesDeSaude,
            pontosDeResfriamento = pontosDeResfriamento,
            nivelCalor = nivelCalor,
            recomendacoes = recomendacoes,
            eventos = eventos,
            nomeImagemFundo = nomeImagemFundo,
            // Novos campos
            estacoesChuva = estacoesChuva,
            estacoesMeteorologicas = estacoesMeteorologicas,
            estacoesCeu = estacoesCeu,
            infoSol = infoSol,
            loadingProgress = 1f,
            loadingMessage = "Dados carregados em ${getLanguageName(languageCode)}!",
            currentLanguage = languageCode
        )

        // Atualiza o estado da UI uma única vez no final
        _uiState.value = finalState

        Log.d(TAG, "✅ Carregamento paralelo ($languageCode) completo em ${System.currentTimeMillis() - startTime}ms")

        // Salva no cache com prefixo do idioma
        saveToCache(finalState, languageCode)
    }

    /**
     * Função para salvar cache específico do idioma
     */
    private fun saveToCache(state: CORUiState, languageCode: String) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                // Salva com prefixo do idioma para diferenciação
                cacheManager.saveList("alertas_$languageCode", state.alertas, isOffline = false)
                cacheManager.saveList("infoTempo_$languageCode", state.infoTempo, isOffline = false)
                cacheManager.saveList("infoTransito_$languageCode", state.infoTransito, isOffline = false)

                // Dados independentes de idioma (sem prefixo)
                cacheManager.saveList("eventos", state.eventos, isOffline = false)
                cacheManager.saveList("cameras", state.cameras, isOffline = false)
                cacheManager.saveList("sirenes", state.sirenes, isOffline = false)
                cacheManager.saveList("pontosDeApoio", state.pontosDeApoio, isOffline = false)
                cacheManager.saveList("unidadesDeSaude", state.unidadesDeSaude, isOffline = false)
                cacheManager.saveList("pontosDeResfriamento", state.pontosDeResfriamento, isOffline = false)
                cacheManager.saveList("estacoesChuva", state.estacoesChuva, isOffline = false)
                cacheManager.saveList("estacoesMeteorologicas", state.estacoesMeteorologicas, isOffline = false)
                cacheManager.saveList("estacoesCeu", state.estacoesCeu, isOffline = false)
                cacheManager.saveList("infoSol", state.infoSol, isOffline = false)
                state.nivelCalor?.let { cacheManager.saveList("nivelCalor", listOf(it), isOffline = false) }
                cacheManager.saveList("recomendacoes", state.recomendacoes, isOffline = false)

                Log.d(TAG, "💾 Dados salvos no cache para idioma: $languageCode")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro ao salvar no cache ($languageCode): ${e.message}")
            }
        }
    }

    /**
     * Carrega cache específico do idioma
     */
    private suspend fun loadFromCacheIfAvailable() {
        try {
            val language = localizationViewModel.currentLanguage.value

            // Tenta carregar dados específicos do idioma primeiro, depois fallback
            val alertas = cacheManager.getList("alertas_$language", Alerta::class.java)
                ?: cacheManager.getList("alertas", Alerta::class.java)
                ?: emptyList()

            val infoTempo = cacheManager.getList("infoTempo_$language", InformeTempo::class.java)
                ?: cacheManager.getList("infoTempo", InformeTempo::class.java)
                ?: emptyList()

            val infoTransito = cacheManager.getList("infoTransito_$language", InformeTransito::class.java)
                ?: cacheManager.getList("infoTransito", InformeTransito::class.java)
                ?: emptyList()

            // Dados independentes de idioma
            val eventos = cacheManager.getList("eventos", Evento::class.java) ?: emptyList()
            val cameras = cacheManager.getList("cameras", Camera::class.java) ?: emptyList()
            val sirenes = cacheManager.getList("sirenes", Sirene::class.java) ?: emptyList()
            val pontosDeApoio = cacheManager.getList("pontosDeApoio", PontoDeApoio::class.java) ?: emptyList()
            val unidadesDeSaude = cacheManager.getList("unidadesDeSaude", PontoDeApoio::class.java) ?: emptyList()
            val pontosDeResfriamento = cacheManager.getList("pontosDeResfriamento", PontoDeApoio::class.java) ?: emptyList()
            val estacoesChuva = cacheManager.getList("estacoesChuva", EstacaoChuva::class.java) ?: emptyList()
            val estacoesMeteorologicas = cacheManager.getList("estacoesMeteorologicas", EstacaoMeteorologica::class.java) ?: emptyList()
            val estacoesCeu = cacheManager.getList("estacoesCeu", EstacaoCeu::class.java) ?: emptyList()
            val infoSol = cacheManager.getList("infoSol", InfoTempoSol::class.java) ?: emptyList()
            val nivelCalor = cacheManager.getList("nivelCalor", NivelCalor::class.java)?.firstOrNull()
            val recomendacoes = cacheManager.getList("recomendacoes", Recomendacao::class.java) ?: emptyList()

            // Se há dados em cache, criar estado offline
            val totalCachedData = alertas.size + eventos.size + cameras.size + sirenes.size + infoTempo.size + infoTransito.size
            if (totalCachedData > 0) {
                val cachedState = CORUiState(
                    isLoading = false,
                    isDataLoaded = true,
                    currentStage = 1, // Valor padrão
                    nomeImagemFundo = atualizarImagemFundo(estacoesChuva, estacoesCeu, infoSol.firstOrNull()),
                    eventos = eventos,
                    alertas = alertas,
                    infoTempo = infoTempo,
                    infoTransito = infoTransito,
                    cameras = cameras,
                    sirenes = sirenes,
                    pontosDeApoio = pontosDeApoio,
                    unidadesDeSaude = unidadesDeSaude,
                    pontosDeResfriamento = pontosDeResfriamento,
                    nivelCalor = nivelCalor,
                    recomendacoes = recomendacoes,
                    estacoesChuva = estacoesChuva,
                    estacoesMeteorologicas = estacoesMeteorologicas,
                    estacoesCeu = estacoesCeu,
                    infoSol = infoSol,
                    isOffline = true,
                    error = "Modo offline - Dados em ${getLanguageName(language)}",
                    currentLanguage = language
                )

                _uiState.value = cachedState
                Log.d(TAG, "📱 Dados carregados do cache para idioma: $language")
            } else {
                Log.d(TAG, "📱 Nenhum dado encontrado no cache")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao carregar cache", e)
        }
    }

    // ================================
    // MÉTODOS AUXILIARES
    // ================================

    private suspend fun <T> tryFetch(dataName: String, fetcher: suspend () -> T): T? {
        return try {
            Log.d(TAG, "📡 Carregando $dataName...")
            val result = fetcher()
            Log.d(TAG, "✅ $dataName carregado")
            result
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao carregar $dataName: ${e.message}")
            null
        }
    }

    private fun updateProgress(progress: Float, message: String) {
        _uiState.update { it.copy(loadingProgress = progress, loadingMessage = message) }
    }

    private fun handleError(errorMessage: String, errorType: ErrorType) {
        _uiState.update {
            it.copy(
                isLoading = false,
                isDataLoaded = it.isDataLoaded,
                error = errorMessage,
                errorType = errorType,
                retryCount = it.retryCount + 1,
                isRetrying = false
            )
        }
    }

    /**
     * Função auxiliar para nome do idioma
     */
    private fun getLanguageName(languageCode: String): String {
        return LocalizationViewModel.supportedLanguages
            .find { it.code == languageCode }?.name ?: languageCode
    }

    /**
     * Atualiza a imagem de fundo baseada nas condições climáticas
     */
    private fun atualizarImagemFundo(
        estacoesChuva: List<EstacaoChuva>,
        estacoesCeu: List<EstacaoCeu>,
        solInfo: InfoTempoSol?
    ): String {
        val chuvaMedia = estacoesChuva
            .filterNot { it.situ?.contains("atraso", ignoreCase = true) ?: true }
            .mapNotNull { it.chuva1?.toDouble() }
            .maxOrNull() ?: 0.0

        val condicaoCeu = estacoesCeu.firstOrNull()?.ceu ?: "0"
        val isNight = isNightTime(solInfo)

        return when {
            chuvaMedia > 1 -> if (isNight) "chuva_noite" else "chuva_dia"
            chuvaMedia != 0.0 -> if (isNight) "noite_nublado_p" else "dia_nublado_p"
            else -> when (condicaoCeu) {
                "0" -> if (isNight) "noite_claro_p" else "dia_claro_p"
                "1" -> if (isNight) "noite_nuvens_p" else "dia_nuvens_p"
                "2" -> if (isNight) "noite_nublado_p" else "dia_nublado_p"
                else -> if (isNight) "noite_claro_p" else "dia_claro_p"
            }
        }.also {
            Log.d(TAG, "🌤️ Imagem de fundo: $it (chuva: ${chuvaMedia}mm, céu: $condicaoCeu, noite: $isNight)")
        }
    }

    /**
     * Verifica se é período noturno
     */
    private fun isNightTime(solInfo: InfoTempoSol?): Boolean {
        if (solInfo?.nascer == null || solInfo.por == null) {
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            return hour < 6 || hour >= 18
        }
        val now = Date()
        return now.before(solInfo.nascer) || now.after(solInfo.por)
    }
}

class NoDataException(message: String) : Exception(message)
