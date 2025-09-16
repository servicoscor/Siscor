package bugarin.t.comando.data

import bugarin.t.comando.data.Evento
import com.google.gson.annotations.SerializedName
import retrofit2.http.GET
import retrofit2.http.Query

// ✅ MUDANÇA: A maioria dos retornos foi alterada de volta para "String",
// para que possamos fazer o parsing manual no repositório,
// assim como é feito no projeto Swift.

interface CORApiService {

    @GET("alertas_api")
    suspend fun getAlertas(): String // Retorna String

    @GET("ttempo_api")
    suspend fun getInformesTempo(): String // Retorna String

    @GET("transito_api")
    suspend fun getInformesTransito(): String // Retorna String

    @GET("eventos_json_api_app")
    suspend fun getEventos(): EventosResponse // Este retorna JSON, está correto

    @GET("cameras_api")
    suspend fun getCameras(): String // Retorna String

    @GET("sirene_api")
    suspend fun getSirenes(): String // Retorna String

    @GET("pa_api")
    suspend fun getPontosApoio(): String // Retorna String

    @GET("cf_api")
    suspend fun getUnidadesSaude(): String // Retorna String

    @GET("ph_api")
    suspend fun getPontosResfriamento(): String // Retorna String

    @GET("calor_api")
    suspend fun getNivelCalor(): String // Retorna String

    @GET("recomenda_api")
    suspend fun getRecomendacoes(): String // Retorna String

    @GET("chuva_api")
    suspend fun getEstacoesChuva(): String // Retorna String

    @GET("ceu_api")
    suspend fun getEstacoesCeu(): String // Retorna String

    @GET("sol_api")
    suspend fun getInfoSol(): String // Retorna String

    @GET("tempo_api")
    suspend fun getEstacoesMeteorologicas(): String // Retorna String

    @GET("estagio_api_app")
    suspend fun getEstagioOperacional(): String // Retorna String

    @GET("interdicoes_api")
    suspend fun getInterdicoes(): String // Retorna String
}

// Esta classe continua necessária para o endpoint de eventos.
data class EventosResponse(
    @SerializedName("eventos")
    val eventos: List<Evento>
)