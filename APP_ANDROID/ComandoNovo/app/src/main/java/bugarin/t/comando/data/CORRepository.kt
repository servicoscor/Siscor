package bugarin.t.comando.data

import android.location.Location
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.*

@Singleton
class CORRepository @Inject constructor(
    private val apiService: NativeApiService
) {
    companion object {
        private const val TAG = "CORRepository"

        // Limites otimizados para evitar OOM
        private const val MAX_ALERTAS = 50
        private const val MAX_EVENTOS = 100
        // Limite mais alto que 100, mas evita travar a UI ao criar milhares de objetos de uma vez
        private const val MAX_CAMERAS = 1200
        private const val MAX_SIRENES = 100
        private const val MAX_PONTOS = 10000
        private const val MAX_ESTACOES = 100
        private const val MAX_INFORMES = 20
    }

    // Cache simples para evitar reprocessamento
    private var lastDataLoad = 0L
    private var cachedBundle: CORDataBundle? = null
    private val cacheValidityMs = 30_000L // 30 segundos

    // ================================
    // MÉTODOS COM SUPORTE A IDIOMAS
    // ================================

    // ALERTAS - Com suporte a idiomas
    suspend fun getAlertas(languageCode: String = "pt"): List<Alerta> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando alertas para idioma: $languageCode")
            val response = apiService.getAlertas(languageCode)

            if (response.isBlank()) {
                Log.w(TAG, "Resposta de alertas vazia para idioma: $languageCode")
                return@withContext emptyList<Alerta>()
            }

            val alertas = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_ALERTAS)
                .mapNotNull { line ->
                    parseAlertaSafely(line)
                }
                .toList()

            Log.d(TAG, "Alertas carregados ($languageCode): ${alertas.size}")
            alertas
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar alertas para idioma: $languageCode", e)
            throw e
        }
    }

    // Compatibilidade com código existente
    suspend fun getAlertas(): List<Alerta> = getAlertas("pt")

    // INFORMES DE TEMPO - Com suporte a idiomas
    suspend fun getInformesTempo(languageCode: String = "pt"): List<InformeTempo> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando informes de tempo para idioma: $languageCode")
            val response = apiService.getInformesTempo(languageCode)

            if (response.isBlank()) {
                return@withContext emptyList<InformeTempo>()
            }

            val informes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_INFORMES)
                .map { InformeTempo(texto = it) }
                .toList()

            Log.d(TAG, "Informes de tempo carregados ($languageCode): ${informes.size}")
            informes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar informes de tempo para idioma: $languageCode", e)
            throw e
        }
    }

    // Compatibilidade
    suspend fun getInformesTempo(): List<InformeTempo> = getInformesTempo("pt")

    // INFORMES DE TRÂNSITO - Com suporte a idiomas
    suspend fun getInformesTransito(languageCode: String = "pt"): List<InformeTransito> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando informes de trânsito para idioma: $languageCode")
            val response = apiService.getInformesTransito(languageCode)

            if (response.isBlank()) {
                return@withContext emptyList<InformeTransito>()
            }

            val informes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_INFORMES)
                .map { InformeTransito(texto = it.replace(";", "\n")) }
                .toList()

            Log.d(TAG, "Informes de trânsito carregados ($languageCode): ${informes.size}")
            informes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar informes de trânsito para idioma: $languageCode", e)
            throw e
        }
    }

    // Compatibilidade
    suspend fun getInformesTransito(): List<InformeTransito> = getInformesTransito("pt")

    // ================================
    // MÉTODOS QUE NÃO DEPENDEM DE IDIOMA
    // ================================

    suspend fun getEventos(data: String? = null): List<Evento> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando eventos...")
            val eventosResponse = apiService.getEventos()

            val eventos = eventosResponse.eventos
                .asSequence()
                .filter { evento ->
                    !evento.nome.isNullOrBlank()
                }
                .take(MAX_EVENTOS)
                .toList()

            Log.d(TAG, "Eventos carregados: ${eventos.size}")
            eventos
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar eventos", e)
            throw e
        }
    }

    suspend fun getCameras(): List<Camera> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando câmeras...")
            val response = apiService.getCameras()

            if (response.isBlank()) {
                return@withContext emptyList<Camera>()
            }

            val cameras = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_CAMERAS)
                .mapNotNull { line ->
                    parseCameraSafely(line)
                }
                .toList()

            Log.d(TAG, "Câmeras carregadas: ${cameras.size}")
            cameras
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar câmeras", e)
            throw e
        }
    }

    // Câmeras mais próximas
    suspend fun getCamerasNearby(
        userLat: Double? = null,
        userLon: Double? = null,
        maxCameras: Int = MAX_CAMERAS
    ): List<Camera> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando câmeras próximas de ($userLat, $userLon)...")
            val response = apiService.getCameras()

            if (response.isBlank()) {
                return@withContext emptyList<Camera>()
            }

            val allCameras = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .mapNotNull { line ->
                    parseCameraSafely(line)
                }
                .toList()

            Log.d(TAG, "Total de câmeras disponíveis: ${allCameras.size}")

            if (userLat == null || userLon == null) {
                Log.d(TAG, "Sem localização do usuário, retornando primeiras $maxCameras câmeras")
                return@withContext allCameras.take(maxCameras)
            }

            val camerasWithDistance = allCameras
                .filter { camera ->
                    camera.lat != null && camera.lon != null
                }
                .map { camera ->
                    val distance = calculateDistanceSimple(
                        userLat, userLon,
                        camera.lat!!, camera.lon!!
                    )
                    CameraWithDistance(camera, distance)
                }
                .sortedBy { it.distance }
                .take(maxCameras)
                .map { it.camera }

            Log.d(TAG, "Câmeras próximas carregadas: ${camerasWithDistance.size}")
            camerasWithDistance

        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar câmeras próximas", e)
            throw e
        }
    }

    // Câmeras dentro de um raio específico
    suspend fun getCamerasWithinRadius(
        userLat: Double,
        userLon: Double,
        radiusKm: Float = 50f,
        maxCameras: Int = MAX_CAMERAS
    ): List<Camera> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando câmeras dentro de ${radiusKm}km...")

            val response = apiService.getCameras()
            if (response.isBlank()) {
                return@withContext emptyList<Camera>()
            }

            val radiusMeters = radiusKm * 1000

            val cameras = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .mapNotNull { line ->
                    parseCameraSafely(line)
                }
                .filter { camera ->
                    camera.lat != null && camera.lon != null
                }
                .map { camera ->
                    val distance = calculateDistanceSimple(
                        userLat, userLon,
                        camera.lat!!, camera.lon!!
                    )
                    CameraWithDistance(camera, distance)
                }
                .filter { it.distance <= radiusMeters }
                .sortedBy { it.distance }
                .take(maxCameras)
                .map { it.camera }
                .toList()

            Log.d(TAG, "Câmeras encontradas no raio: ${cameras.size}")
            cameras

        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar câmeras por raio", e)
            throw e
        }
    }

    suspend fun getSirenes(): List<Sirene> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando sirenes...")
            val response = apiService.getSirenes()

            if (response.isBlank()) {
                return@withContext emptyList<Sirene>()
            }

            val sirenes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_SIRENES)
                .mapNotNull { line ->
                    parseSireneSafely(line)
                }
                .toList()

            Log.d(TAG, "Sirenes carregadas: ${sirenes.size}")
            sirenes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar sirenes", e)
            throw e
        }
    }

    // Sirenes próximas
    suspend fun getSirenesNearby(
        userLat: Double,
        userLon: Double,
        maxSirenes: Int = MAX_SIRENES
    ): List<Sirene> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando sirenes próximas...")
            val response = apiService.getSirenes()

            if (response.isBlank()) {
                return@withContext emptyList<Sirene>()
            }

            val sirenes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .mapNotNull { line ->
                    parseSireneSafely(line)
                }
                .filter { sirene ->
                    sirene.lat != null && sirene.lon != null
                }
                .map { sirene ->
                    val distance = calculateDistanceSimple(
                        userLat, userLon,
                        sirene.lat!!, sirene.lon!!
                    )
                    SireneWithDistance(sirene, distance)
                }
                .sortedBy { it.distance }
                .take(maxSirenes)
                .map { it.sirene }
                .toList()

            Log.d(TAG, "Sirenes próximas carregadas: ${sirenes.size}")
            sirenes

        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar sirenes próximas", e)
            throw e
        }
    }

    // Função auxiliar genérica para pontos de apoio
    private suspend fun parsePontoDeApoio(apiCall: suspend () -> String, tipo: String): List<PontoDeApoio> =
        withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Buscando $tipo...")
                val response = apiCall()

                if (response.isBlank()) {
                    return@withContext emptyList<PontoDeApoio>()
                }

                val pontos = response.lines()
                    .asSequence()
                    .filter { it.isNotBlank() }
                    .take(MAX_PONTOS)
                    .mapNotNull { line ->
                        parsePontoSafely(line, tipo)
                    }
                    .toList()

                Log.d(TAG, "$tipo carregados: ${pontos.size}")
                pontos
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar $tipo", e)
                throw e
            }
        }

    suspend fun getPontosApoio() = parsePontoDeApoio({ apiService.getPontosApoio() }, "pontos de apoio")
    suspend fun getUnidadesSaude() = parsePontoDeApoio({ apiService.getUnidadesSaude() }, "unidades de saúde")
    suspend fun getPontosResfriamento() = parsePontoDeApoio({ apiService.getPontosResfriamento() }, "pontos de resfriamento")

    suspend fun getEstagioOperacional(): EstagioOperacional = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando estágio operacional...")
            val estagio = EstagioOperacional(estagio = apiService.getEstagioOperacional().cleaned())
            Log.d(TAG, "Estágio operacional: ${estagio.estagio}")
            estagio
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar estágio operacional", e)
            EstagioOperacional(estagio = "1") // Valor padrão
        }
    }

    suspend fun getNivelCalor(): NivelCalor = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando nível de calor...")
            val nivel = NivelCalor(situacao = apiService.getNivelCalor().cleaned())
            Log.d(TAG, "Nível de calor: ${nivel.situacao}")
            nivel
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar nível de calor", e)
            NivelCalor(situacao = "Normal") // Valor padrão
        }
    }

    suspend fun getRecomendacoes(): List<Recomendacao> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando recomendações...")
            val response = apiService.getRecomendacoes()

            if (response.isBlank()) {
                return@withContext emptyList<Recomendacao>()
            }

            val recomendacoes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(20)
                .map { Recomendacao(nome = it) }
                .toList()

            Log.d(TAG, "Recomendações carregadas: ${recomendacoes.size}")
            recomendacoes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar recomendações", e)
            throw e
        }
    }

    suspend fun getInterdicoes(): List<Interdicao> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando interdições...")
            val response = apiService.getInterdicoes()

            if (response.isBlank()) {
                return@withContext emptyList<Interdicao>()
            }

            val interdicoes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(50)
                .map { Interdicao(nor = it) }
                .toList()

            Log.d(TAG, "Interdições carregadas: ${interdicoes.size}")
            interdicoes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar interdições", e)
            throw e
        }
    }

    suspend fun getEstacoesChuva(): List<EstacaoChuva> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando estações de chuva...")
            val response = apiService.getEstacoesChuva()

            if (response.isBlank()) {
                return@withContext emptyList<EstacaoChuva>()
            }

            val estacoes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_ESTACOES)
                .mapNotNull { line ->
                    parseEstacaoChuva(line)
                }
                .toList()

            Log.d(TAG, "Estações de chuva carregadas: ${estacoes.size}")
            estacoes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar estações de chuva", e)
            throw e
        }
    }

    suspend fun getEstacoesCeu(): List<EstacaoCeu> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando estações de céu...")
            val response = apiService.getEstacoesCeu()

            if (response.isBlank()) {
                return@withContext emptyList<EstacaoCeu>()
            }

            val estacoes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_ESTACOES)
                .mapNotNull { line ->
                    parseEstacaoCeu(line)
                }
                .toList()

            Log.d(TAG, "Estações de céu carregadas: ${estacoes.size}")
            estacoes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar estações de céu", e)
            throw e
        }
    }

    suspend fun getInfoSol(): List<InfoTempoSol> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando informações do sol...")
            val response = apiService.getInfoSol()

            if (response.isBlank()) {
                return@withContext emptyList<InfoTempoSol>()
            }

            val infos = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(10)
                .mapNotNull { line ->
                    parseInfoSol(line)
                }
                .toList()

            Log.d(TAG, "Informações do sol carregadas: ${infos.size}")
            infos
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar informações do sol", e)
            throw e
        }
    }

    suspend fun getEstacoesMeteorologicas(): List<EstacaoMeteorologica> = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Buscando estações meteorológicas...")
            val response = apiService.getEstacoesMeteorologicas()

            if (response.isBlank()) {
                return@withContext emptyList<EstacaoMeteorologica>()
            }

            val estacoes = response.lines()
                .asSequence()
                .filter { it.isNotBlank() }
                .take(MAX_ESTACOES)
                .mapNotNull { line ->
                    parseEstacaoMeteorologica(line)
                }
                .toList()

            Log.d(TAG, "Estações meteorológicas carregadas: ${estacoes.size}")
            estacoes
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar estações meteorológicas", e)
            throw e
        }
    }

    // ================================
    // MÉTODO PRINCIPAL OTIMIZADO COM IDIOMA
    // ================================

    suspend fun getAllCORDataOptimized(
        languageCode: String = "pt",
        userLat: Double? = null,
        userLon: Double? = null
    ): CORDataBundle = withContext(Dispatchers.IO) {
        // Verificar cache primeiro
        val now = System.currentTimeMillis()
        cachedBundle?.let { bundle ->
            if (now - lastDataLoad < cacheValidityMs) {
                Log.d(TAG, "Usando dados do cache")
                return@withContext bundle
            }
        }

        try {
            Log.d(TAG, "Carregando dados COR para idioma '$languageCode' ${if (userLat != null && userLon != null) "com localização" else "sem localização"}...")

            // Carregar dados críticos em paralelo (com idioma)
            val alertasDeferred = async {
                try { getAlertas(languageCode) } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar alertas ($languageCode)", e)
                    emptyList<Alerta>()
                }
            }

            val informesTempoDeferred = async {
                try { getInformesTempo(languageCode) } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar informes tempo ($languageCode)", e)
                    emptyList<InformeTempo>()
                }
            }

            val informesTransitoDeferred = async {
                try { getInformesTransito(languageCode) } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar informes trânsito ($languageCode)", e)
                    emptyList<InformeTransito>()
                }
            }

            val estagioDeferred = async {
                try { getEstagioOperacional() } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar estágio", e)
                    EstagioOperacional("1")
                }
            }

            // Dados secundários em segundo plano
            val eventosDeferred = async {
                try { getEventos() } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar eventos", e)
                    emptyList<Evento>()
                }
            }

            // Usar getCamerasNearby se temos localização
            val camerasDeferred = async {
                try {
                    if (userLat != null && userLon != null) {
                        getCamerasNearby(userLat, userLon)
                    } else {
                        getCameras()
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar câmeras", e)
                    emptyList<Camera>()
                }
            }

            // Sirenes próximas também
            val sirenesDeferred = async {
                try {
                    if (userLat != null && userLon != null) {
                        getSirenesNearby(userLat, userLon)
                    } else {
                        getSirenes()
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Falha ao carregar sirenes", e)
                    emptyList<Sirene>()
                }
            }

            // Aguardar todos os resultados
            val alertas = alertasDeferred.await()
            val informesTempo = informesTempoDeferred.await()
            val informesTransito = informesTransitoDeferred.await()
            val estagio = estagioDeferred.await()
            val eventos = eventosDeferred.await()
            val cameras = camerasDeferred.await()
            val sirenes = sirenesDeferred.await()

            Log.d(TAG, "Dados COR carregados ($languageCode): alertas=${alertas.size}, eventos=${eventos.size}, cameras=${cameras.size}, sirenes=${sirenes.size}")

            val bundle = CORDataBundle(
                alertas = alertas,
                eventos = eventos,
                cameras = cameras,
                sirenes = sirenes,
                estagio = estagio,
                informesTempo = informesTempo,
                informesTransito = informesTransito,
                loadTimestamp = now
            )

            // Salvar no cache
            cachedBundle = bundle
            lastDataLoad = now

            bundle

        } catch (e: Exception) {
            Log.e(TAG, "Erro ao carregar dados COR para idioma: $languageCode", e)
            throw e
        }
    }

    // Compatibilidade
    suspend fun getAllCORDataOptimized(
        userLat: Double? = null,
        userLon: Double? = null
    ): CORDataBundle = getAllCORDataOptimized("pt", userLat, userLon)

    // ================================
    // FUNÇÕES AUXILIARES DE PARSING
    // ================================

    private fun parseAlertaSafely(line: String): Alerta? {
        return try {
            val components = line.split(";")
            if (components.size >= 5) {
                Alerta(
                    nome = components[0].cleaned(),
                    mensagem = components[1].cleaned().replace("jump_line", "\n"),
                    geo = components[2],
                    audio = components[3],
                    audiourl = components[4]
                )
            } else {
                Log.w(TAG, "Linha de alerta inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de alerta: $line", e)
            null
        }
    }

    private fun parseCameraSafely(line: String): Camera? {
        return try {
            val components = line.split(";")
            if (components.size >= 4) {
                Camera(
                    lat = components[0].cleanedForNumber().toDoubleOrNull(),
                    lon = components[1].cleanedForNumber().toDoubleOrNull(),
                    nome = components[2].cleaned(),
                    apiId = components[3].cleaned()
                )
            } else {
                Log.w(TAG, "Linha de câmera inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de câmera: $line", e)
            null
        }
    }

    private fun parseSireneSafely(line: String): Sirene? {
        return try {
            val components = line.split(";")
            if (components.size >= 7) {
                Sirene(
                    lat = components[0].cleanedForNumber().toDoubleOrNull(),
                    lon = components[1].cleanedForNumber().toDoubleOrNull(),
                    nome = components[2].cleaned(),
                    status = components[6].cleaned(),
                    loc = components.getOrNull(5)?.cleaned()
                )
            } else {
                Log.w(TAG, "Linha de sirene inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de sirene: $line", e)
            null
        }
    }

    private fun parsePontoSafely(line: String, tipo: String): PontoDeApoio? {
        return try {
            val components = line.split(";")
            if (components.size >= 4) {
                PontoDeApoio(
                    nome = components[0].cleaned(),
                    lat = components[1].cleanedForNumber().toDoubleOrNull(),
                    lon = components[2].cleanedForNumber().toDoubleOrNull(),
                    endereco = components[3].cleaned()
                )
            } else {
                Log.w(TAG, "Linha de $tipo inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de $tipo: $line", e)
            null
        }
    }

    private fun parseEstacaoChuva(line: String): EstacaoChuva? {
        return try {
            val c = line.split(";")
            if (c.size >= 13) {
                EstacaoChuva(
                    lat = c[0].cleanedForNumber().toDoubleOrNull(),
                    lon = c[1].cleanedForNumber().toDoubleOrNull(),
                    nome = c[2].cleaned(),
                    municipio = c[3].cleaned(),
                    data = c[4].cleaned(),
                    chuvaI = c[5].cleanedForNumber().toFloatOrNull(),
                    chuva1 = c[6].cleanedForNumber().toFloatOrNull(),
                    chuva4 = c[7].cleanedForNumber().toFloatOrNull(),
                    chuva24 = c[8].cleanedForNumber().toFloatOrNull(),
                    chuva96 = c[9].cleanedForNumber().toFloatOrNull(),
                    chuva30 = c[10].cleanedForNumber().toFloatOrNull(),
                    situ = c[11].cleaned(),
                    fonte = c[12].cleaned()
                )
            } else {
                Log.w(TAG, "Linha de estação de chuva inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de estação de chuva: $line", e)
            null
        }
    }

    private fun parseEstacaoCeu(line: String): EstacaoCeu? {
        return try {
            val c = line.split(";")
            if (c.size >= 5) {
                EstacaoCeu(
                    lat = c[0].cleanedForNumber().toDoubleOrNull(),
                    lon = c[1].cleanedForNumber().toDoubleOrNull(),
                    nome = c[2].cleaned(),
                    data = c[3].cleaned(),
                    ceu = c[4].cleaned()
                )
            } else {
                Log.w(TAG, "Linha de estação de céu inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de estação de céu: $line", e)
            null
        }
    }

    private fun parseInfoSol(line: String): InfoTempoSol? {
        return try {
            val c = line.split(";")
            if (c.size >= 2) {
                val nascerStr = c[0].cleaned()
                val porStr = c[1].cleaned()

                val nascer = parseTimeOrDate(nascerStr)
                val por = parseTimeOrDate(porStr)

                InfoTempoSol(
                    nascer = nascer,
                    por = por
                )
            } else {
                Log.w(TAG, "Linha de info sol inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de info sol: $line", e)
            null
        }
    }

    private fun parseTimeOrDate(timeStr: String): Date? {
        return try {
            val today = Calendar.getInstance()

            if (timeStr.matches(Regex("\\d{2}:\\d{2}"))) {
                val timeParts = timeStr.split(":")
                val hour = timeParts[0].toInt()
                val minute = timeParts[1].toInt()

                today.set(Calendar.HOUR_OF_DAY, hour)
                today.set(Calendar.MINUTE, minute)
                today.set(Calendar.SECOND, 0)
                today.set(Calendar.MILLISECOND, 0)

                today.time
            } else {
                val sdf = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
                sdf.parse(timeStr)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro parseando tempo: $timeStr", e)
            null
        }
    }

    private fun parseEstacaoMeteorologica(line: String): EstacaoMeteorologica? {
        return try {
            val c = line.split(";")
            if (c.size >= 8) {
                EstacaoMeteorologica(
                    nome = c[0].cleaned(),
                    lat = c[1].cleanedForNumber().toDoubleOrNull(),
                    lon = c[2].cleanedForNumber().toDoubleOrNull(),
                    temMed = c[3].cleanedForNumber().toFloatOrNull(),  // Fixed: was c[4]
                    umdMed = c[4].cleanedForNumber().toFloatOrNull(),  // Fixed: was c[5]
                    dirMed = c[5].cleaned(),                           // Fixed: was c[6]
                    velMed = c[6].cleanedForNumber().toFloatOrNull(),  // Fixed: was c[7]
                    data = c[7].cleaned(),                             // Fixed: was c[4]
                    fonte = if (c.size > 8) c[8].cleaned() else ""     // Optional field
                )
            } else {
                Log.w(TAG, "Linha de estação meteorológica inválida: $line")
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Erro processando linha de estação meteorológica: $line", e)
            null
        }
    }

    // ================================
    // FUNÇÕES UTILITÁRIAS
    // ================================

    // Limpeza de cache
    fun clearCache() {
        cachedBundle = null
        lastDataLoad = 0L
        apiService.clearConnectionPool()
        Log.d(TAG, "Cache limpo")
    }

    // Cálculo de distância usando Location do Android
    private fun calculateDistanceSimple(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ): Float {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0] // distância em metros
    }
}

// Bundle otimizado para dados carregados
data class CORDataBundle(
    val alertas: List<Alerta>,
    val eventos: List<Evento>,
    val cameras: List<Camera>,
    val sirenes: List<Sirene>,
    val estagio: EstagioOperacional,
    val informesTempo: List<InformeTempo>,
    val informesTransito: List<InformeTransito>,
    val loadTimestamp: Long
)

// Data classes auxiliares para armazenar com distância
private data class CameraWithDistance(
    val camera: Camera,
    val distance: Float
)

private data class SireneWithDistance(
    val sirene: Sirene,
    val distance: Float
)

// Funções de extensão auxiliares otimizadas
private fun String.cleaned(): String {
    return this.replace("'", "").trim()
}

private fun String.cleanedForNumber(): String {
    return this.replace("'", "").replace(",", ".").trim()
}
