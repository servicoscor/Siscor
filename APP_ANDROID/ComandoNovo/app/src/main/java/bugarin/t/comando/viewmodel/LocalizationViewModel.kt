package bugarin.t.comando.viewmodel

import android.app.Application
import android.content.Context
import android.location.Location
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.AndroidViewModel
import bugarin.t.comando.utils.LocationManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
import javax.inject.Inject

@HiltViewModel
class LocalizationViewModel @Inject constructor(
    application: Application,
    // ✅ ARQUITETURA: O LocationManager é injetado e gerenciado por este ViewModel.
    private val locationManager: LocationManager
) : AndroidViewModel(application) {

    companion object {
        private const val TAG = "LocalizationManager"
        private const val PREFS_NAME = "cor_preferences"
        private const val KEY_LANGUAGE = "app_language"

        val supportedLanguages = listOf(
            Language("pt", "🇧🇷", "Português"),
            Language("en", "🇺🇸", "English"),
            Language("es", "🇪🇸", "Español"),
            Language("fr", "🇫🇷", "Français"),
            Language("zh", "🇨🇳", "中文")
        )
    }

    data class Language(val code: String, val flag: String, val name: String)

    private val context: Context get() = getApplication()

    private val sharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val _currentLanguage = MutableStateFlow(getInitialLanguage())
    val currentLanguage: StateFlow<String> = _currentLanguage.asStateFlow()

    // ✅ ARQUITETURA: Expõe a localização a partir do LocationManager.
    val userLocation: StateFlow<Location?> = locationManager.location

    init {
        Log.d(TAG, "🌐 LocalizationViewModel initialized with language: ${_currentLanguage.value}")
        // Aplica o locale inicial
        applyLocale(_currentLanguage.value)
    }

    // --- Métodos Públicos para a UI ---

    fun setLanguage(languageCode: String) {
        if (!supportedLanguages.any { it.code == languageCode }) {
            Log.w(TAG, "Unsupported language code: $languageCode")
            return
        }
        if (languageCode != _currentLanguage.value) {
            _currentLanguage.value = languageCode
            sharedPreferences.edit().putString(KEY_LANGUAGE, languageCode).apply()
            applyLocale(languageCode)
            Log.d(TAG, "Language changed to: $languageCode")
        }
    }

    /**
     * Atualiza o locale da aplicação.
     * Este método é chamado quando a configuração muda (como rotação de tela).
     */
    fun refreshLocale() {
        val currentLang = _currentLanguage.value
        applyLocale(currentLang)
        Log.d(TAG, "Locale refreshed with language: $currentLang")
    }

    /**
     * Inicia as atualizações de localização. Chamado pela UI quando a localização é necessária.
     */
    fun startLocationUpdates() {
        locationManager.startLocationUpdates()
    }

    /**
     * Para as atualizações de localização.
     */
    fun stopLocationUpdates() {
        locationManager.stopLocationUpdates()
    }

    /**
     * Chamado pelo handler de permissão quando o usuário concede ou nega a permissão.
     */
    fun onLocationPermissionResult(isGranted: Boolean) {
        if (isGranted) {
            startLocationUpdates()
        } else {
            Log.w(TAG, "Permissão de localização negada pelo usuário.")
        }
    }

    fun getString(key: String, vararg args: Any): String {
        return try {
            val resourceId = context.resources.getIdentifier(key, "string", context.packageName)
            if (resourceId != 0) {
                if (args.isNotEmpty()) {
                    context.getString(resourceId, *args)
                } else {
                    context.getString(resourceId)
                }
            } else {
                Log.w(TAG, "String resource not found for key: $key")
                key // Retorna a chave se a tradução não for encontrada
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting string for key: $key", e)
            key
        }
    }

    /**
     * Obtém o idioma atual.
     */
    fun getCurrentLanguage(): Language? {
        return supportedLanguages.find { it.code == _currentLanguage.value }
    }

    /**
     * Verifica se um idioma é suportado.
     */
    fun isLanguageSupported(languageCode: String): Boolean {
        return supportedLanguages.any { it.code == languageCode }
    }

    // --- Lógica Interna e Ciclo de Vida ---

    private fun getInitialLanguage(): String {
        val savedLanguage = sharedPreferences.getString(KEY_LANGUAGE, null)
        if (savedLanguage != null && supportedLanguages.any { it.code == savedLanguage }) {
            return savedLanguage
        }
        val systemLanguage = Locale.getDefault().language
        return supportedLanguages.find { it.code == systemLanguage }?.code ?: "en" // Fallback para inglês
    }

    /**
     * Aplica o locale especificado no contexto da aplicação.
     */
    private fun applyLocale(languageCode: String) {
        try {
            val locale = Locale(languageCode)
            Locale.setDefault(locale)

            val resources = context.resources
            val configuration = resources.configuration
            configuration.setLocale(locale)

            // Atualiza a configuração
            @Suppress("DEPRECATION")
            resources.updateConfiguration(configuration, resources.displayMetrics)

            Log.d(TAG, "Locale applied successfully: $languageCode")
        } catch (e: Exception) {
            Log.e(TAG, "Error applying locale: $languageCode", e)
        }
    }

    /**
     * ✅ ROBUSTEZ: Garante que as atualizações de localização parem quando o ViewModel
     * for destruído, prevenindo vazamentos de memória e de bateria.
     */
    override fun onCleared() {
        super.onCleared()
        locationManager.stopLocationUpdates()
        Log.d(TAG, "ViewModel destruído, atualizações de localização paradas.")
    }
}

/**
 * Utilitário Composable que envolve a UI e fornece um Contexto com a localização correta
 * com base no código do idioma fornecido.
 */
@Composable
fun ProvideLocalizedContext(
    languageCode: String,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val localizedContext = remember(languageCode) {
        val locale = Locale(languageCode)
        Locale.setDefault(locale)
        val configuration = android.content.res.Configuration(context.resources.configuration)
        configuration.setLocale(locale)
        context.createConfigurationContext(configuration)
    }
    CompositionLocalProvider(LocalContext provides localizedContext, content = content)
}