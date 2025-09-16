package bugarin.t.comando.data

import java.util.Locale
import com.google.android.gms.maps.model.LatLng
import com.google.gson.annotations.SerializedName
import java.text.SimpleDateFormat
import java.util.Date

// ✅ Interface Mappable otimizada
interface Mappable {
    val loc: String?
    val coordinate: LatLng?
}

// ✅ CORREÇÃO CRÍTICA: IDs estáticos baseados em dados reais
data class Alerta(
    val nome: String? = null,
    val data: String? = null,
    val mensagem: String? = null,
    val geo: String? = null,
    val audio: String? = null,
    val audiourl: String? = null
) {
    // ✅ ID baseado no conteúdo, não aleatório
    val id: String get() = "${nome?.hashCode() ?: 0}_${mensagem?.hashCode() ?: 0}".replace("-", "")
}

data class Evento(
    @SerializedName("Nome do evento")
    val nome: String? = null,

    @SerializedName("Data")
    val dataString: String? = null,

    @SerializedName("Hora de início")
    val horaInicio: String? = null,

    @SerializedName("Hora de encerramento")
    val horaEncerramento: String? = null,

    @SerializedName("Local")
    val local: String? = null,

    @SerializedName("Zona")
    val zona: String? = null,

    @SerializedName("Quantidade de pessoas")
    val quantidadePessoasString: String? = null,

    @SerializedName("Criticidade")
    val criticidade: String? = null,

    @SerializedName("Fonte")
    val fonte: String? = null,

    @SerializedName("Latitude")
    val latString: String? = null,

    @SerializedName("Longitude")
    val lonString: String? = null,

    @SerializedName("Importante")
    val importanteString: String? = null,

    @SerializedName("ImagemURL")
    val imagemURL: String? = null,

    @SerializedName("Descricao")
    val descricao: String? = null,

    @SerializedName("Categoria")
    val categoria: String? = null
) {
    // ✅ ID baseado em dados únicos do evento
    val id: String get() = "${nome?.hashCode() ?: 0}_${dataString?.hashCode() ?: 0}_${local?.hashCode() ?: 0}".replace("-", "")

    // ✅ CACHED: Conversões pesadas só executam uma vez
    private var _data: Date? = null
    val data: Date?
        get() {
            if (_data == null && dataString != null) {
                try {
                    val sdf = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
                    _data = sdf.parse(dataString)
                } catch (e: Exception) {
                    _data = null
                }
            }
            return _data
        }

    private var _quantidadePessoas: Int? = null
    val quantidadePessoas: Int?
        get() {
            if (_quantidadePessoas == null) {
                _quantidadePessoas = quantidadePessoasString?.toIntOrNull()
            }
            return _quantidadePessoas
        }

    private var _lat: Double? = null
    val lat: Double?
        get() {
            if (_lat == null) {
                _lat = latString?.toDoubleOrNull()
            }
            return _lat
        }

    private var _lon: Double? = null
    val lon: Double?
        get() {
            if (_lon == null) {
                _lon = lonString?.toDoubleOrNull()
            }
            return _lon
        }

    private var _importante: Boolean? = null
    val importante: Boolean
        get() {
            if (_importante == null) {
                _importante = importanteString?.equals("Sim", ignoreCase = true) ?: false
            }
            return _importante!!
        }

    private var _tipo: TipoEvento? = null
    val tipo: TipoEvento
        get() {
            if (_tipo == null) {
                _tipo = categoria?.let { TipoEvento.fromString(it) } ?: inferirTipoPorNome()
            }
            return _tipo!!
        }

    private fun inferirTipoPorNome(): TipoEvento {
        val nomeLower = nome?.lowercase() ?: return TipoEvento.OUTRO
        return when {
            nomeLower.contains("corrida") || nomeLower.contains("run") -> TipoEvento.ESPORTIVO
            nomeLower.contains("show") || nomeLower.contains("música") || nomeLower.contains("orquestra") -> TipoEvento.MUSICAL
            nomeLower.contains("festival") || nomeLower.contains("festa") -> TipoEvento.CULTURAL
            nomeLower.contains("congresso") || nomeLower.contains("feira") -> TipoEvento.EDUCACIONAL
            nomeLower.contains("gastro") || nomeLower.contains("comida") -> TipoEvento.GASTRONOMICO
            else -> TipoEvento.OUTRO
        }
    }

    private var _coordinate: LatLng? = null
    val coordinate: LatLng?
        get() {
            if (_coordinate == null && lat != null && lon != null) {
                _coordinate = LatLng(lat!!, lon!!)
            }
            return _coordinate
        }
}

enum class TipoEvento(val value: String) {
    CONGRESSO("Congresso"),
    CULTURAL("Cultural"),
    ESPORTIVO("Esportivo"),
    FEIRA("Feira"),
    MUSICAL("Musical"),
    MANIFESTACAO("Manifestação"),
    RELIGIOSO("Religioso"),
    REVEILLON("Réveillon"),
    CARNAVAL_BAIRRO("Carnaval de bairro"),
    CARNAVAL_DESFILES("Carnaval: Desfiles"),
    CARNAVAL_ENSAIOS("Carnaval: Ensaios Técnicos"),
    CARNAVAL_BLOCOS("Carnaval: Blocos"),
    CARNAVAL_PALCOS("Carnaval: Palcos"),
    BLOCOS_NAO_OFICIAIS("Blocos não oficiais"),
    SIMULADO("Simulado"),
    ACADEMICOS("Acadêmicos"),
    G20("G20"),
    CORPORATIVO("Corporativo"),
    POLITICO("Político"),
    GASTRONOMICO("Gastronômico"),
    EDUCACIONAL("Educacional"),
    OUTRO("Outro");

    companion object {
        fun fromString(value: String): TipoEvento? {
            return values().find { it.value.equals(value, ignoreCase = true) }
        }
    }
}

// ✅ OTIMIZADOS: Todos os outros models
data class Camera(
    val apiId: String? = null,
    val nome: String? = null,
    val lat: Double? = null,
    val lon: Double? = null
) {
    val id: String get() = apiId ?: "${nome?.hashCode() ?: 0}_${lat?.hashCode() ?: 0}".replace("-", "")

    private var _coordinate: LatLng? = null
    val coordinate: LatLng?
        get() {
            if (_coordinate == null && lat != null && lon != null) {
                _coordinate = LatLng(lat, lon)
            }
            return _coordinate
        }
}

data class Sirene(
    val nome: String? = null,
    val status: String? = null,
    val lat: Double? = null,
    val lon: Double? = null,
    override val loc: String? = null
) : Mappable {
    val id: String get() = "${nome?.hashCode() ?: 0}_${lat?.hashCode() ?: 0}".replace("-", "")

    private var _coordinate: LatLng? = null
    override val coordinate: LatLng?
        get() {
            if (_coordinate == null && lat != null && lon != null) {
                _coordinate = LatLng(lat, lon)
            }
            return _coordinate
        }
}

data class PontoDeApoio(
    val nome: String? = null,
    val endereco: String? = null,
    override val loc: String? = null,
    val status: String? = null,
    val lat: Double? = null,
    val lon: Double? = null
) : Mappable {
    val id: String get() = "${nome?.hashCode() ?: 0}_${endereco?.hashCode() ?: 0}".replace("-", "")

    private var _coordinate: LatLng? = null
    override val coordinate: LatLng?
        get() {
            if (_coordinate == null && lat != null && lon != null) {
                _coordinate = LatLng(lat, lon)
            }
            return _coordinate
        }
}

data class InformeTempo(
    val texto: String? = null
) {
    val id: String get() = "${texto?.hashCode() ?: 0}".replace("-", "")
}

data class InformeTransito(
    val texto: String? = null
) {
    val id: String get() = "${texto?.hashCode() ?: 0}".replace("-", "")
}

data class EstacaoChuva(
    val nome: String? = null,
    val data: String? = null,
    val municipio: String? = null,
    val apiId: String? = null,
    val chuvaI: Float? = null,
    val chuva1: Float? = null,
    val chuva4: Float? = null,
    val chuva24: Float? = null,
    val chuva96: Float? = null,
    val chuva30: Float? = null,
    val lat: Double? = null,
    val lon: Double? = null,
    val situ: String? = null,
    val fonte: String? = null
) {
    val id: String get() = apiId ?: "${nome?.hashCode() ?: 0}_${municipio?.hashCode() ?: 0}".replace("-", "")

    private var _coordinate: LatLng? = null
    val coordinate: LatLng?
        get() {
            if (_coordinate == null && lat != null && lon != null) {
                _coordinate = LatLng(lat, lon)
            }
            return _coordinate
        }
}

data class EstacaoMeteorologica(
    val nome: String? = null,
    val fonte: String? = null,
    val data: String? = null,
    val temMed: Float? = null,
    val umdMed: Float? = null,
    val velMed: Float? = null,
    val dirMed: String? = null,
    val lat: Double? = null,
    val lon: Double? = null
) {
    val id: String get() = "${nome?.hashCode() ?: 0}_${fonte?.hashCode() ?: 0}".replace("-", "")

    private var _coordinate: LatLng? = null
    val coordinate: LatLng?
        get() {
            if (_coordinate == null && lat != null && lon != null) {
                _coordinate = LatLng(lat, lon)
            }
            return _coordinate
        }
}

data class EstacaoCeu(
    val nome: String? = null,
    val data: String? = null,
    val ceu: String? = null,
    val lat: Double? = null,
    val lon: Double? = null
) {
    val id: String get() = "${nome?.hashCode() ?: 0}_${ceu?.hashCode() ?: 0}".replace("-", "")
}

data class InfoTempoSol(
    val nascer: Date? = null,
    val por: Date? = null
) {
    val id: String get() = "${nascer?.hashCode() ?: 0}_${por?.hashCode() ?: 0}".replace("-", "")
}

data class NivelCalor(
    val situacao: String? = null
) {
    val id: String get() = "${situacao?.hashCode() ?: 0}".replace("-", "")
}

data class Recomendacao(
    val nome: String? = null
) {
    val id: String get() = "${nome?.hashCode() ?: 0}".replace("-", "")
}

data class EstagioOperacional(
    val estagio: String? = null
) {
    val id: String get() = "${estagio?.hashCode() ?: 0}".replace("-", "")
}

data class Interdicao(
    val via: String? = null,
    val status: String? = null,
    val poli: String? = null,
    val reg: String? = null,
    val nor: String? = null
) {
    val id: String get() = "${via?.hashCode() ?: 0}_${nor?.hashCode() ?: 0}".replace("-", "")
}

// ✅ Restante das classes sem mudanças críticas
enum class CategoriaPonto {
    TODOS,
    PATRIMONIO,
    PRAIA,
    PARQUE,
    MUSEU,
    CULTURA,
    ESPORTE,
    ARTE,
    BIBLIOTECA,
    MIRANTE,
    OUTRO
}

data class LocalizedText(
    val pt: String,
    val en: String,
    val es: String,
    val fr: String,
    val zh: String
) {
    fun text(language: String): String {
        return when (language) {
            "en" -> en
            "es" -> es
            "fr" -> fr
            "zh" -> zh
            else -> pt
        }
    }
}

data class PontoTuristico(
    val id: String,
    val nomeLocalizado: LocalizedText? = null,
    val textoLocalizado: LocalizedText? = null,
    val categoria: CategoriaPonto,
    val endereco: String? = null,
    val telefone: String? = null,
    val website: String? = null,
    val coordenadas: LatLng? = null,
    val avaliacao: Float? = null,
    val horarioFuncionamento: String? = null,
    val precoEntrada: String? = null
) {
    val nome: String? get() = nomeLocalizado?.pt
    val texto: String? get() = textoLocalizado?.pt
    val end: String? get() = endereco

    fun getNomeLocalizado(language: String): String {
        return nomeLocalizado?.text(language) ?: ""
    }

    fun getTextoLocalizado(language: String): String {
        return textoLocalizado?.text(language) ?: ""
    }
}