package bugarin.t.comando.data

import android.content.Context
import android.util.Log
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class NativeApiService(
    private val context: Context,
    private val gson: Gson
) {
    companion object {
        private const val TAG = "NativeApiService"
        private const val BASE_URL = "https://aplicativo.cocr.com.br"

        // ✅ URLs por idioma para alertas
        private val ALERTAS_URLS = mapOf(
            "pt" to "$BASE_URL/alertas_api",
            "en" to "$BASE_URL/alertas_api_en",
            "es" to "$BASE_URL/alertas_api_es",
            "fr" to "$BASE_URL/alertas_api_fr",
            "zh" to "$BASE_URL/alertas_api_ch"
        )

        // ✅ URLs por idioma para informes de tempo (usando ttempo_api)
        private val INFORMES_TEMPO_URLS = mapOf(
            "pt" to "$BASE_URL/ttempo_api",
            "en" to "$BASE_URL/ttempo_api_en",
            "es" to "$BASE_URL/ttempo_api_es",
            "fr" to "$BASE_URL/ttempo_api_fr",
            "zh" to "$BASE_URL/ttempo_api_ch"
        )

        // ✅ URLs por idioma para informes de trânsito (usando transito_api)
        private val INFORMES_TRANSITO_URLS = mapOf(
            "pt" to "$BASE_URL/transito_api",
            "en" to "$BASE_URL/transito_api_en",
            "es" to "$BASE_URL/transito_api_es",
            "fr" to "$BASE_URL/transito_api_fr",
            "zh" to "$BASE_URL/transito_api_ch"
        )

        // URLs que não dependem de idioma (mantém URLs originais)
        private const val EVENTOS_URL = "$BASE_URL/eventos_json_api"
        private const val CAMERAS_URL = "$BASE_URL/cameras_api"
        private const val SIRENES_URL = "$BASE_URL/sirene_api"
        private const val PONTOS_APOIO_URL = "$BASE_URL/pa_api"
        private const val UNIDADES_SAUDE_URL = "$BASE_URL/cf_api"
        private const val PONTOS_RESFRIAMENTO_URL = "$BASE_URL/ph_api"
        private const val ESTAGIO_OPERACIONAL_URL = "$BASE_URL/estagio_api"
        private const val NIVEL_CALOR_URL = "$BASE_URL/calor_api"
        private const val RECOMENDACOES_URL = "$BASE_URL/recomendacoes_api"
        private const val INTERDICOES_URL = "$BASE_URL/interdicoes_api"
        private const val ESTACOES_CHUVA_URL = "$BASE_URL/chuva_api"
        private const val ESTACOES_CEU_URL = "$BASE_URL/ceu_api"
        private const val INFO_SOL_URL = "$BASE_URL/sol_api"
        private const val ESTACOES_METEOROLOGICAS_URL = "$BASE_URL/tempo_api"
    }

    private val connectionPool by lazy {
        // Pool de conexões reutilizável
        mutableMapOf<String, HttpURLConnection>()
    }

    // ✅ ALERTAS - Com suporte a idiomas
    suspend fun getAlertas(languageCode: String = "pt"): String {
        val url = ALERTAS_URLS[languageCode] ?: ALERTAS_URLS["pt"]!!
        Log.d(TAG, "Carregando alertas para idioma '$languageCode' da URL: $url")

        return withContext(Dispatchers.IO) {
            try {
                val response = makeHttpRequest(url)
                Log.d(TAG, "Alertas carregados com sucesso para idioma: $languageCode (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar alertas para idioma '$languageCode'", e)
                throw e
            }
        }
    }

    // ✅ Compatibilidade com código existente
    suspend fun getAlertas(): String = getAlertas("pt")

    // ✅ INFORMES DE TEMPO - Com suporte a idiomas
    suspend fun getInformesTempo(languageCode: String = "pt"): String {
        val url = INFORMES_TEMPO_URLS[languageCode] ?: INFORMES_TEMPO_URLS["pt"]!!
        Log.d(TAG, "Carregando informes de tempo para idioma '$languageCode' da URL: $url")

        return withContext(Dispatchers.IO) {
            try {
                val response = makeHttpRequest(url)
                Log.d(TAG, "Informes de tempo carregados com sucesso para idioma: $languageCode (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar informes de tempo para idioma '$languageCode'", e)
                throw e
            }
        }
    }

    // ✅ Compatibilidade
    suspend fun getInformesTempo(): String = getInformesTempo("pt")

    // ✅ INFORMES DE TRÂNSITO - Com suporte a idiomas
    suspend fun getInformesTransito(languageCode: String = "pt"): String {
        val url = INFORMES_TRANSITO_URLS[languageCode] ?: INFORMES_TRANSITO_URLS["pt"]!!
        Log.d(TAG, "Carregando informes de trânsito para idioma '$languageCode' da URL: $url")

        return withContext(Dispatchers.IO) {
            try {
                val response = makeHttpRequest(url)
                Log.d(TAG, "Informes de trânsito carregados com sucesso para idioma: $languageCode (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar informes de trânsito para idioma '$languageCode'", e)
                throw e
            }
        }
    }

    // ✅ Compatibilidade
    suspend fun getInformesTransito(): String = getInformesTransito("pt")

    // ✅ EVENTOS - Não depende de idioma
    suspend fun getEventos(): EventosResponse {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando eventos da URL: $EVENTOS_URL")
                val response = makeHttpRequest(EVENTOS_URL)
                val eventosResponse = gson.fromJson(response, EventosResponse::class.java)
                Log.d(TAG, "Eventos carregados com sucesso: ${eventosResponse.eventos.size} eventos")
                eventosResponse
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar eventos", e)
                throw e
            }
        }
    }

    // ✅ CÂMERAS - Não depende de idioma
    suspend fun getCameras(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando câmeras da URL: $CAMERAS_URL")
                val response = makeHttpRequest(CAMERAS_URL)
                Log.d(TAG, "Câmeras carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar câmeras", e)
                throw e
            }
        }
    }

    // ✅ SIRENES - Não depende de idioma
    suspend fun getSirenes(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando sirenes da URL: $SIRENES_URL")
                val response = makeHttpRequest(SIRENES_URL)
                Log.d(TAG, "Sirenes carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar sirenes", e)
                throw e
            }
        }
    }

    // ✅ PONTOS DE APOIO - Não depende de idioma
    suspend fun getPontosApoio(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando pontos de apoio da URL: $PONTOS_APOIO_URL")
                val response = makeHttpRequest(PONTOS_APOIO_URL)
                Log.d(TAG, "Pontos de apoio carregados com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar pontos de apoio", e)
                throw e
            }
        }
    }

    // ✅ UNIDADES DE SAÚDE - Não depende de idioma
    suspend fun getUnidadesSaude(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando unidades de saúde da URL: $UNIDADES_SAUDE_URL")
                val response = makeHttpRequest(UNIDADES_SAUDE_URL)
                Log.d(TAG, "Unidades de saúde carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar unidades de saúde", e)
                throw e
            }
        }
    }

    // ✅ PONTOS DE RESFRIAMENTO - Não depende de idioma
    suspend fun getPontosResfriamento(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando pontos de resfriamento da URL: $PONTOS_RESFRIAMENTO_URL")
                val response = makeHttpRequest(PONTOS_RESFRIAMENTO_URL)
                Log.d(TAG, "Pontos de resfriamento carregados com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar pontos de resfriamento", e)
                throw e
            }
        }
    }

    // ✅ ESTÁGIO OPERACIONAL - Não depende de idioma
    suspend fun getEstagioOperacional(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando estágio operacional da URL: $ESTAGIO_OPERACIONAL_URL")
                val response = makeHttpRequest(ESTAGIO_OPERACIONAL_URL)
                Log.d(TAG, "Estágio operacional carregado com sucesso: $response")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar estágio operacional", e)
                throw e
            }
        }
    }

    // ✅ NÍVEL DE CALOR - Não depende de idioma
    suspend fun getNivelCalor(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando nível de calor da URL: $NIVEL_CALOR_URL")
                val response = makeHttpRequest(NIVEL_CALOR_URL)
                Log.d(TAG, "Nível de calor carregado com sucesso: $response")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar nível de calor", e)
                throw e
            }
        }
    }

    // ✅ RECOMENDAÇÕES - Não depende de idioma
    suspend fun getRecomendacoes(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando recomendações da URL: $RECOMENDACOES_URL")
                val response = makeHttpRequest(RECOMENDACOES_URL)
                Log.d(TAG, "Recomendações carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar recomendações", e)
                throw e
            }
        }
    }

    // ✅ INTERDIÇÕES - Não depende de idioma
    suspend fun getInterdicoes(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando interdições da URL: $INTERDICOES_URL")
                val response = makeHttpRequest(INTERDICOES_URL)
                Log.d(TAG, "Interdições carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar interdições", e)
                throw e
            }
        }
    }

    // ✅ ESTAÇÕES DE CHUVA - Não depende de idioma
    suspend fun getEstacoesChuva(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando estações de chuva da URL: $ESTACOES_CHUVA_URL")
                val response = makeHttpRequest(ESTACOES_CHUVA_URL)
                Log.d(TAG, "Estações de chuva carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar estações de chuva", e)
                throw e
            }
        }
    }

    // ✅ ESTAÇÕES DE CÉU - Não depende de idioma
    suspend fun getEstacoesCeu(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando estações de céu da URL: $ESTACOES_CEU_URL")
                val response = makeHttpRequest(ESTACOES_CEU_URL)
                Log.d(TAG, "Estações de céu carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar estações de céu", e)
                throw e
            }
        }
    }

    // ✅ INFO SOL - Não depende de idioma
    suspend fun getInfoSol(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando informações do sol da URL: $INFO_SOL_URL")
                val response = makeHttpRequest(INFO_SOL_URL)
                Log.d(TAG, "Informações do sol carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar informações do sol", e)
                throw e
            }
        }
    }

    // ✅ ESTAÇÕES METEOROLÓGICAS - Não depende de idioma
    suspend fun getEstacoesMeteorologicas(): String {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Carregando estações meteorológicas da URL: $ESTACOES_METEOROLOGICAS_URL")
                val response = makeHttpRequest(ESTACOES_METEOROLOGICAS_URL)
                Log.d(TAG, "Estações meteorológicas carregadas com sucesso (${response.length} chars)")
                response
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao carregar estações meteorológicas", e)
                throw e
            }
        }
    }

    // ✅ MÉTODOS UTILITÁRIOS

    /**
     * Função utilitária para validar se um idioma é suportado
     */
    fun isLanguageSupported(languageCode: String): Boolean {
        return ALERTAS_URLS.containsKey(languageCode)
    }

    /**
     * Função para obter todos os idiomas suportados
     */
    fun getSupportedLanguages(): Set<String> {
        return ALERTAS_URLS.keys
    }

    /**
     * Função para limpar pool de conexões
     */
    fun clearConnectionPool() {
        connectionPool.clear()
        Log.d(TAG, "Pool de conexões limpo")
    }

    // ✅ MÉTODO AUXILIAR PARA FAZER REQUISIÇÕES HTTP
    private suspend fun makeHttpRequest(url: String): String {
        return withContext(Dispatchers.IO) {
            var connection: HttpURLConnection? = null
            try {
                Log.d(TAG, "Fazendo requisição para: $url")

                connection = URL(url).openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 30000
                connection.setRequestProperty("Accept", "text/plain")
                connection.setRequestProperty("User-Agent", "COR-Mobile-App/1.0")
                connection.setRequestProperty("Connection", "keep-alive")

                val responseCode = connection.responseCode
                Log.d(TAG, "Resposta HTTP: $responseCode para URL: $url")

                when (responseCode) {
                    HttpURLConnection.HTTP_OK -> {
                        val response = connection.inputStream.bufferedReader().use { it.readText() }
                        Log.d(TAG, "Requisição bem-sucedida. Tamanho da resposta: ${response.length} chars")
                        response
                    }
                    HttpURLConnection.HTTP_NOT_FOUND -> {
                        val errorMessage = "Endpoint não encontrado (404): $url"
                        Log.e(TAG, errorMessage)
                        throw IOException(errorMessage)
                    }
                    HttpURLConnection.HTTP_INTERNAL_ERROR -> {
                        val errorMessage = "Erro interno do servidor (500): $url"
                        Log.e(TAG, errorMessage)
                        throw IOException(errorMessage)
                    }
                    else -> {
                        val errorMessage = "HTTP Error $responseCode para URL: $url"
                        Log.e(TAG, errorMessage)
                        throw IOException(errorMessage)
                    }
                }
            } catch (e: IOException) {
                Log.e(TAG, "Erro de IO na requisição HTTP para $url", e)
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Erro inesperado na requisição HTTP para $url", e)
                throw IOException("Erro inesperado: ${e.message}", e)
            } finally {
                connection?.disconnect()
            }
        }
    }
}