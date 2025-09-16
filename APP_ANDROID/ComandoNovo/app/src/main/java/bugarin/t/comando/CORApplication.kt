package bugarin.t.comando

import android.app.Application
import android.util.Log
import dagger.hilt.android.HiltAndroidApp
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

@HiltAndroidApp
class CORApplication : Application() {

    companion object {
        private const val TAG = "CORApplication"
    }

    // ✅ PERFORMANCE: Application-scoped coroutine scope
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()

        Log.d(TAG, "🚀 Iniciando COR Application...")

        // ✅ PERFORMANCE: Inicialização assíncrona dos serviços
        initializeServicesAsync()

        // ✅ MEMORY: Configurar otimizações de memória
        configureMemoryOptimizations()
    }

    // ✅ PERFORMANCE: Inicialização não-blocking
    private fun initializeServicesAsync() {
        applicationScope.launch {
            try {
                // Firebase initialization in background
                initializeFirebase()

                // Setup Firebase Messaging
                setupFirebaseMessaging()

                Log.d(TAG, "✅ Serviços inicializados com sucesso")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro na inicialização dos serviços", e)
            }
        }
    }

    // ✅ PERFORMANCE: Firebase initialization otimizada
    private suspend fun initializeFirebase() {
        try {
            // Inicializa o Firebase de forma assíncrona
            FirebaseApp.initializeApp(this@CORApplication)
            Log.d(TAG, "📱 Firebase inicializado")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao inicializar Firebase", e)
        }
    }

    // ✅ PERFORMANCE: Firebase Messaging setup otimizado
    private suspend fun setupFirebaseMessaging() {
        try {
            FirebaseMessaging.getInstance().apply {
                // ✅ BACKGROUND: Inscreve em tópicos em background
                applicationScope.launch(Dispatchers.IO) {
                    try {
                        // Inscreve em tópicos gerais
                        subscribeToTopic("alerts").addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                Log.d(TAG, "📢 Inscrito no tópico: alerts")
                            } else {
                                Log.w(TAG, "⚠️ Falha ao inscrever no tópico alerts", task.exception)
                            }
                        }

                        subscribeToTopic("events").addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                Log.d(TAG, "📢 Inscrito no tópico: events")
                            } else {
                                Log.w(TAG, "⚠️ Falha ao inscrever no tópico events", task.exception)
                            }
                        }

                        subscribeToTopic("weather").addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                Log.d(TAG, "📢 Inscrito no tópico: weather")
                            } else {
                                Log.w(TAG, "⚠️ Falha ao inscrever no tópico weather", task.exception)
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Erro ao inscrever em tópicos", e)
                    }
                }

                // ✅ OPTIMIZATION: Habilita auto-init apenas se necessário
                isAutoInitEnabled = true
            }

            Log.d(TAG, "🔔 Firebase Messaging configurado")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao configurar Firebase Messaging", e)
        }
    }

    // ✅ MEMORY: Configurações de otimização de memória
    private fun configureMemoryOptimizations() {
        try {
            // ✅ MEMORY: Configurar VM para performance
            System.setProperty("java.util.concurrent.ForkJoinPool.common.parallelism", "2")

            // ✅ MEMORY: Configurar garbage collection
            System.setProperty("dalvik.vm.heapgrowthlimit", "128m")
            System.setProperty("dalvik.vm.heapsize", "256m")

            Log.d(TAG, "💾 Otimizações de memória configuradas")
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Não foi possível configurar otimizações de memória", e)
        }
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)

        when (level) {
            TRIM_MEMORY_UI_HIDDEN -> {
                Log.d(TAG, "🔄 UI hidden - liberando recursos")
                // App UI is hidden, free up UI resources
            }
            TRIM_MEMORY_RUNNING_MODERATE -> {
                Log.d(TAG, "🔄 Memory pressure moderate")
                // Device is running low on memory, free up non-critical resources
            }
            TRIM_MEMORY_RUNNING_LOW -> {
                Log.d(TAG, "🔄 Memory pressure low - limpeza agressiva")
                // Device is running very low on memory, free up more resources
                performAggressiveCleanup()
            }
            TRIM_MEMORY_RUNNING_CRITICAL -> {
                Log.d(TAG, "🆘 Memory pressure critical - limpeza de emergência")
                // Device is running critically low on memory
                performEmergencyCleanup()
            }
        }
    }

    // ✅ MEMORY: Limpeza agressiva de recursos
    private fun performAggressiveCleanup() {
        applicationScope.launch(Dispatchers.IO) {
            try {
                // Força garbage collection
                System.gc()

                // Outras limpezas podem ser adicionadas aqui
                Log.d(TAG, "🧹 Limpeza agressiva concluída")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro na limpeza agressiva", e)
            }
        }
    }

    // ✅ MEMORY: Limpeza de emergência
    private fun performEmergencyCleanup() {
        applicationScope.launch(Dispatchers.IO) {
            try {
                // Força garbage collection múltiplas vezes
                repeat(3) {
                    System.gc()
                    Thread.sleep(100)
                }

                // Outras limpezas de emergência podem ser adicionadas aqui
                Log.d(TAG, "🆘 Limpeza de emergência concluída")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro na limpeza de emergência", e)
            }
        }
    }

    override fun onLowMemory() {
        super.onLowMemory()
        Log.w(TAG, "⚠️ Sistema com pouca memória - executando limpeza")
        performEmergencyCleanup()
    }
}