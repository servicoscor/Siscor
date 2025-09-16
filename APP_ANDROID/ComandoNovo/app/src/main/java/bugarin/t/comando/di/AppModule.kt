package bugarin.t.comando.di

import android.app.Application
import android.content.Context
import bugarin.t.comando.data.CORRepository
import bugarin.t.comando.data.NativeApiService
import bugarin.t.comando.utils.LocationManager
import bugarin.t.comando.utils.NetworkMonitor
import bugarin.t.comando.viewmodel.LocalizationViewModel
import com.google.gson.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import java.lang.reflect.Type
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideLocationManager(@ApplicationContext context: Context): LocationManager {
        return LocationManager(context)
    }

    @Provides
    @Singleton
    fun provideNetworkMonitor(@ApplicationContext context: Context): NetworkMonitor {
        return NetworkMonitor(context)
    }

    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder()
            .registerTypeAdapter(Date::class.java, DateTypeAdapter())
            .setLenient()
            .create()
    }

    @Provides
    @Singleton
    fun provideNativeApiService(
        @ApplicationContext context: Context,
        gson: Gson
    ): NativeApiService {
        return NativeApiService(context, gson)
    }

    @Provides
    @Singleton
    fun provideCORRepository(apiService: NativeApiService): CORRepository {
        return CORRepository(apiService)
    }

    // ===============================
    // INJEÇÃO DO LOCALIZATIONVIEWMODEL
    // ===============================

    /**
     * Provê o LocalizationViewModel como singleton.
     *
     * IMPORTANTE: Esta abordagem funciona, mas se você preferir manter
     * @HiltViewModel no LocalizationViewModel, remova este provider e
     * certifique-se de que o LocalizationViewModel seja injetado
     * corretamente no CORViewModel via constructor.
     *
     * Esta implementação garante que haja apenas uma instância do
     * LocalizationViewModel em toda a aplicação, o que é importante
     * para observação de mudanças de idioma.
     */
    @Provides
    @Singleton
    fun provideLocalizationViewModel(
        @ApplicationContext context: Context,
        locationManager: LocationManager
    ): LocalizationViewModel {
        // Como LocalizationViewModel estende AndroidViewModel,
        // precisamos criar uma instância manualmente passando Application
        val application = context.applicationContext as Application
        return LocalizationViewModel(
            application = application,
            locationManager = locationManager
        )
    }

    // ===============================
    // ALTERNATIVA COM @HiltViewModel
    // ===============================

    /*
    Se você preferir usar @HiltViewModel no LocalizationViewModel:

    1. Remova o provider acima
    2. Certifique-se de que LocalizationViewModel tenha @HiltViewModel
    3. No CORViewModel, injete via construtor:

    @HiltViewModel
    class CORViewModel @Inject constructor(
        private val repository: CORRepository,
        private val cacheManager: CacheManager,
        private val localizationViewModel: LocalizationViewModel // <- Isso deve funcionar
    ) : ViewModel()

    A abordagem com provider (acima) é mais explícita e garante
    que seja singleton, enquanto @HiltViewModel pode criar múltiplas
    instâncias dependendo do contexto.
    */
}

// ===============================
// CUSTOM ADAPTERS
// ===============================

/**
 * Custom adapter for Date objects to handle multiple formats.
 * Usado pelo Gson para serializar/deserializar objetos Date
 * com múltiplos formatos de data.
 */
class DateTypeAdapter : JsonDeserializer<Date>, JsonSerializer<Date> {

    // Lista de formatos de data suportados
    private val dateFormats = listOf(
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault()),
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()),
        SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()),
        SimpleDateFormat("dd/MM/yyyy HH:mm:ss", Locale.getDefault()),
        SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()),
        SimpleDateFormat("HH:mm", Locale.getDefault()) // Para horários do sol
    ).apply {
        // Define o timezone para todos os formatadores
        forEach { it.timeZone = TimeZone.getTimeZone("GMT-3") }
    }

    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?
    ): Date? {
        val dateString = json?.asString ?: return null

        // Tenta fazer parse da string de data com cada formato suportado
        for (format in dateFormats) {
            try {
                return format.parse(dateString)
            } catch (e: Exception) {
                // Ignora e tenta o próximo formato
                continue
            }
        }

        // Retorna null se nenhum formato corresponder
        return null
    }

    override fun serialize(
        src: Date?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement? {
        // Serializa datas usando o formato principal
        return src?.let {
            JsonPrimitive(dateFormats.first().format(it))
        }
    }
}