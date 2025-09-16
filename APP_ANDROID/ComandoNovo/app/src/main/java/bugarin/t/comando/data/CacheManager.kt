package bugarin.t.comando.data

import androidx.room.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.delay
import kotlinx.coroutines.supervisorScope
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

@Singleton
class CacheManager @Inject constructor(
    private val cacheDao: CacheDao,
    private val gson: Gson
) {
    companion object {
        // Reduzido drasticamente para evitar ANR e OOM
        const val CACHE_DURATION_MINUTES = 2L // Reduzido de 3 para 2 minutos
        const val CACHE_DURATION_OFFLINE = 6L * 60L // Reduzido de 12 para 6 horas

        // Limites mais agressivos para evitar OOM
        private const val MAX_CACHE_ENTRIES = 10 // Reduzido de 20 para 10
        private const val MAX_JSON_SIZE = 200_000 // 200KB (reduzido de 500KB)
        private const val MAX_LIST_SIZE = 100 // Reduzido de 200 para 100
        private const val BATCH_SIZE = 3 // Reduzido de 5 para 3

        // Limites específicos
        private const val MAX_MAP_ITEMS = 50 // Limite específico para mapas
        private const val MAX_CAMERA_ITEMS = 30 // Limite para câmeras
        private const val MAX_ALERT_ITEMS = 20 // Limite para alertas críticos
    }

    // WEAK REFERENCE para evitar memory leaks
    private val memoryCache = ConcurrentHashMap<String, WeakReference<Any>>(5)

    // MEMORY MONITORING
    @Volatile
    private var lastCleanupTime = System.currentTimeMillis()
    private val cleanupInterval = 30_000L // Limpeza a cada 30 segundos

    suspend fun <T> getList(key: String, clazz: Class<T>): List<T>? = withContext(Dispatchers.IO) {
        try {
            // AUTO-CLEANUP se necessário
            autoCleanupIfNeeded()

            // Check memory cache com WeakReference
            val weakRef = memoryCache[key]
            val cachedData = weakRef?.get()
            @Suppress("UNCHECKED_CAST")
            if (cachedData != null && cachedData is List<*>) {
                android.util.Log.d("CacheManager", "Memory hit: $key")
                return@withContext cachedData as? List<T>
            }

            // Database query com timeout
            val cache = withContext(Dispatchers.IO) {
                try {
                    cacheDao.getCache(key)
                } catch (e: Exception) {
                    android.util.Log.e("CacheManager", "DB error: ${e.message}")
                    null
                }
            } ?: return@withContext null

            // Parse JSON em thread separada
            val result = try {
                withContext(Dispatchers.Default) {
                    val type = TypeToken.getParameterized(List::class.java, clazz).type
                    gson.fromJson<List<T>>(cache.data, type)
                }
            } catch (e: OutOfMemoryError) {
                android.util.Log.e("CacheManager", "OOM parsing $key", e)
                emergencyCleanup()
                null
            } catch (e: Exception) {
                android.util.Log.e("CacheManager", "Parse error: ${e.message}")
                null
            }

            // Cache apenas dados pequenos com WeakReference
            if (result != null && result.size <= 50) {
                memoryCache[key] = WeakReference(result)
            }

            result
        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "getList error: ${e.message}")
            null
        }
    }

    suspend fun <T> saveList(key: String, data: List<T>, isOffline: Boolean = false) =
        withContext(Dispatchers.IO) {
            try {
                // VALIDAÇÃO E LIMITAÇÃO
                val limitedData = when (key) {
                    "cameras" -> data.take(MAX_CAMERA_ITEMS)
                    "alertas", "alertas_pt", "alertas_en", "alertas_es", "alertas_fr", "alertas_zh" -> data.take(MAX_ALERT_ITEMS)
                    "eventos" -> data.take(MAX_MAP_ITEMS)
                    "infoTempo", "infoTempo_pt", "infoTempo_en", "infoTempo_es", "infoTempo_fr", "infoTempo_zh" -> data.take(MAX_ALERT_ITEMS)
                    "infoTransito", "infoTransito_pt", "infoTransito_en", "infoTransito_es", "infoTransito_fr", "infoTransito_zh" -> data.take(MAX_ALERT_ITEMS)
                    else -> data.take(MAX_LIST_SIZE)
                }

                if (limitedData.isEmpty()) {
                    android.util.Log.d("CacheManager", "Empty list for $key")
                    return@withContext
                }

                // Serialização com controle de tamanho
                val json = try {
                    gson.toJson(limitedData)
                } catch (e: OutOfMemoryError) {
                    android.util.Log.e("CacheManager", "OOM serializing $key", e)
                    emergencyCleanup()
                    return@withContext
                }

                // Verificar tamanho do JSON
                if (json.length > MAX_JSON_SIZE) {
                    android.util.Log.w("CacheManager", "JSON too large: ${json.length}")
                    // Tentar salvar metade dos dados
                    val halfData = limitedData.take(limitedData.size / 2)
                    val halfJson = gson.toJson(halfData)
                    if (halfJson.length <= MAX_JSON_SIZE) {
                        saveToDatabase(key, halfJson, isOffline)
                    }
                    return@withContext
                }

                saveToDatabase(key, json, isOffline)

                // Memory cache com WeakReference para dados pequenos
                if (limitedData.size <= 30) {
                    memoryCache[key] = WeakReference(limitedData)
                    if (memoryCache.size > MAX_CACHE_ENTRIES) {
                        cleanWeakReferences()
                    }
                }

            } catch (e: Exception) {
                android.util.Log.e("CacheManager", "Save error: ${e.message}")
            }
        }

    private suspend fun saveToDatabase(key: String, json: String, isOffline: Boolean) {
        try {
            val duration = if (isOffline) CACHE_DURATION_OFFLINE else CACHE_DURATION_MINUTES
            val expiresAt = System.currentTimeMillis() + (duration * 60 * 1000)

            cacheDao.insertCache(
                CacheEntity(
                    key = key,
                    data = json,
                    expiresAt = expiresAt
                )
            )
        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "DB save error: ${e.message}")
        }
    }

    // OTIMIZAÇÃO PARA MAPS - Evitar ANR
    suspend fun saveCORDataOptimized(bundle: CORDataBundle, isOffline: Boolean = false) =
        supervisorScope {
            try {
                android.util.Log.d("CacheManager", "Saving COR bundle...")

                // Salvar dados críticos primeiro (async para não bloquear)
                val criticalJobs = listOf(
                    async { saveList("alertas", bundle.alertas.take(MAX_ALERT_ITEMS), isOffline) },
                    async { saveList("estagio", listOf(bundle.estagio), isOffline) }
                )

                // Salvar dados de mapa com limite reduzido
                val mapJobs = listOf(
                    async {
                        delay(100) // Pequeno delay para evitar sobrecarga
                        saveList("eventos", bundle.eventos.take(MAX_MAP_ITEMS), isOffline)
                    },
                    async {
                        delay(200)
                        saveList("cameras", bundle.cameras.take(MAX_CAMERA_ITEMS), isOffline)
                    },
                    async {
                        delay(300)
                        saveList("sirenes", bundle.sirenes.take(MAX_MAP_ITEMS), isOffline)
                    }
                )

                // ✅ CORRIGIDO: Salvar informes se existirem no bundle
                val informesJobs = listOfNotNull(
                    // Só cria o job se o campo existir no bundle
                    if (hasField(bundle, "informesTempo")) {
                        async {
                            delay(400)
                            val informesTempo = getFieldValue<List<InformeTempo>>(bundle, "informesTempo") ?: emptyList()
                            saveList("infoTempo", informesTempo.take(MAX_ALERT_ITEMS), isOffline)
                        }
                    } else null,

                    if (hasField(bundle, "informesTransito")) {
                        async {
                            delay(500)
                            val informesTransito = getFieldValue<List<InformeTransito>>(bundle, "informesTransito") ?: emptyList()
                            saveList("infoTransito", informesTransito.take(MAX_ALERT_ITEMS), isOffline)
                        }
                    } else null
                )

                // Aguardar dados críticos
                criticalJobs.forEach { it.await() }

                // Aguardar dados secundários sem bloquear se falhar
                mapJobs.forEach {
                    try { it.await() }
                    catch (e: Exception) {
                        android.util.Log.w("CacheManager", "Secondary save failed: ${e.message}")
                    }
                }

                // Aguardar informes se existirem
                informesJobs.forEach {
                    try { it?.await() }
                    catch (e: Exception) {
                        android.util.Log.w("CacheManager", "Informes save failed: ${e.message}")
                    }
                }

                android.util.Log.d("CacheManager", "Bundle saved")

            } catch (e: Exception) {
                android.util.Log.e("CacheManager", "Bundle save error: ${e.message}")
            }
        }

    // CARREGAMENTO OTIMIZADO - Evitar ANR
    suspend fun loadCORDataOptimized(): CORDataBundle? =
        withContext(Dispatchers.IO) {
            try {
                // Carregar dados em paralelo
                coroutineScope {
                    val alertasDeferred = async {
                        getList("alertas", Alerta::class.java) ?: emptyList()
                    }
                    val estagioDeferred = async {
                        getList("estagio", EstagioOperacional::class.java)?.firstOrNull()
                            ?: EstagioOperacional("1")
                    }
                    val eventosDeferred = async {
                        getList("eventos", Evento::class.java) ?: emptyList()
                    }
                    val camerasDeferred = async {
                        getList("cameras", Camera::class.java) ?: emptyList()
                    }
                    val sirenesDeferred = async {
                        getList("sirenes", Sirene::class.java) ?: emptyList()
                    }

                    // ✅ OPCIONAL: Tentar carregar informes se existirem
                    val informesTempoDeferred = async {
                        getList("infoTempo", InformeTempo::class.java) ?: emptyList()
                    }
                    val informesTransitoDeferred = async {
                        getList("infoTransito", InformeTransito::class.java) ?: emptyList()
                    }

                    // Aguardar todos com timeout
                    val alertas = alertasDeferred.await()
                    val estagio = estagioDeferred.await()
                    val eventos = eventosDeferred.await()
                    val cameras = camerasDeferred.await()
                    val sirenes = sirenesDeferred.await()
                    val informesTempo = informesTempoDeferred.await()
                    val informesTransito = informesTransitoDeferred.await()

                    // Validação mínima
                    if (alertas.isEmpty() && eventos.isEmpty() && cameras.isEmpty()) {
                        android.util.Log.w("CacheManager", "Empty cache")
                        return@coroutineScope null
                    }

                    // ✅ ADAPTADO: Criar bundle compatível
                    CORDataBundle(
                        alertas = alertas,
                        eventos = eventos,
                        cameras = cameras,
                        sirenes = sirenes,
                        estagio = estagio,
                        informesTempo = informesTempo,
                        informesTransito = informesTransito,
                        loadTimestamp = System.currentTimeMillis()
                    )
                }
            } catch (e: Exception) {
                android.util.Log.e("CacheManager", "Load error: ${e.message}")
                null
            }
        }

    // ✅ MÉTODO ESPECÍFICO para salvar dados COR com idioma
    suspend fun saveCORDataWithLanguage(
        alertas: List<Alerta>,
        eventos: List<Evento>,
        cameras: List<Camera>,
        sirenes: List<Sirene>,
        estagio: EstagioOperacional,
        informesTempo: List<InformeTempo>,
        informesTransito: List<InformeTransito>,
        languageCode: String = "pt",
        isOffline: Boolean = false
    ) = supervisorScope {
        try {
            android.util.Log.d("CacheManager", "Saving COR data for language: $languageCode")

            // Salvar dados específicos do idioma
            val languageJobs = listOf(
                async { saveList("alertas_$languageCode", alertas.take(MAX_ALERT_ITEMS), isOffline) },
                async { saveList("infoTempo_$languageCode", informesTempo.take(MAX_ALERT_ITEMS), isOffline) },
                async { saveList("infoTransito_$languageCode", informesTransito.take(MAX_ALERT_ITEMS), isOffline) }
            )

            // Salvar dados independentes do idioma
            val generalJobs = listOf(
                async { saveList("eventos", eventos.take(MAX_MAP_ITEMS), isOffline) },
                async { saveList("cameras", cameras.take(MAX_CAMERA_ITEMS), isOffline) },
                async { saveList("sirenes", sirenes.take(MAX_MAP_ITEMS), isOffline) },
                async { saveList("estagio", listOf(estagio), isOffline) }
            )

            // Aguardar todos os jobs
            (languageJobs + generalJobs).forEach {
                try { it.await() }
                catch (e: Exception) {
                    android.util.Log.w("CacheManager", "Save failed: ${e.message}")
                }
            }

            android.util.Log.d("CacheManager", "COR data saved for language: $languageCode")

        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "Save COR data error: ${e.message}")
        }
    }

    // LIMPEZA DE WEAK REFERENCES
    private fun cleanWeakReferences() {
        try {
            val keysToRemove = mutableListOf<String>()
            memoryCache.forEach { (key, weakRef) ->
                if (weakRef.get() == null) {
                    keysToRemove.add(key)
                }
            }
            keysToRemove.forEach { memoryCache.remove(it) }
        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "Weak ref cleanup error: ${e.message}")
        }
    }

    // AUTO-CLEANUP
    private suspend fun autoCleanupIfNeeded() {
        val now = System.currentTimeMillis()
        if (now - lastCleanupTime > cleanupInterval) {
            lastCleanupTime = now
            withContext(Dispatchers.IO) {
                cleanWeakReferences()
                try {
                    cacheDao.deleteExpiredCache(now)
                } catch (e: Exception) {
                    android.util.Log.e("CacheManager", "Auto cleanup error: ${e.message}")
                }
            }
        }
    }

    // EMERGENCY CLEANUP para OOM
    private fun emergencyCleanup() {
        try {
            memoryCache.clear()
            System.gc()
            android.util.Log.w("CacheManager", "Emergency cleanup executed")
        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "Emergency cleanup failed", e)
        }
    }

    // CLEAR ALL
    suspend fun clearAllCache() = withContext(Dispatchers.IO) {
        try {
            memoryCache.clear()
            cacheDao.deleteAllCache()
            lastCleanupTime = System.currentTimeMillis()
            System.gc()
            android.util.Log.d("CacheManager", "All cache cleared")
        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "Clear all error: ${e.message}")
        }
    }

    // MONITORING
    suspend fun getMemoryUsage(): MemoryUsage = withContext(Dispatchers.IO) {
        val runtime = Runtime.getRuntime()
        val activeRefs = memoryCache.count { it.value.get() != null }

        MemoryUsage(
            totalMemory = runtime.totalMemory(),
            freeMemory = runtime.freeMemory(),
            usedMemory = runtime.totalMemory() - runtime.freeMemory(),
            cacheEntriesInMemory = activeRefs,
            cacheEntriesInDb = try { cacheDao.getCacheCount() } catch (e: Exception) { -1 },
            cacheOperations = 0
        )
    }

    // VALIDATION
    suspend fun validateCache(): CacheValidation = withContext(Dispatchers.IO) {
        try {
            cleanWeakReferences()
            val activeRefs = memoryCache.count { it.value.get() != null }
            val dbCount = try { cacheDao.getCacheCount() } catch (e: Exception) { 0 }
            val runtime = Runtime.getRuntime()
            val memoryUsed = runtime.totalMemory() - runtime.freeMemory()
            val memoryPercent = (memoryUsed * 100 / runtime.maxMemory()).toInt()

            CacheValidation(
                isHealthy = activeRefs <= MAX_CACHE_ENTRIES && memoryPercent < 70,
                memoryEntriesCount = activeRefs,
                databaseEntriesCount = dbCount,
                memoryUsagePercent = memoryPercent,
                needsCleanup = memoryPercent > 60 || activeRefs > MAX_CACHE_ENTRIES
            )
        } catch (e: Exception) {
            android.util.Log.e("CacheManager", "Validation error: ${e.message}")
            CacheValidation(isHealthy = false, needsCleanup = true)
        }
    }

    // ✅ MÉTODOS AUXILIARES PARA REFLECTION (se necessário)
    private fun hasField(obj: Any, fieldName: String): Boolean {
        return try {
            obj.javaClass.getDeclaredField(fieldName)
            true
        } catch (e: NoSuchFieldException) {
            false
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> getFieldValue(obj: Any, fieldName: String): T? {
        return try {
            val field = obj.javaClass.getDeclaredField(fieldName)
            field.isAccessible = true
            field.get(obj) as? T
        } catch (e: Exception) {
            null
        }
    }
}

// ✅ DATA CLASSES
data class MemoryUsage(
    val totalMemory: Long,
    val freeMemory: Long,
    val usedMemory: Long,
    val cacheEntriesInMemory: Int,
    val cacheEntriesInDb: Int,
    val cacheOperations: Int
)

data class CacheValidation(
    val isHealthy: Boolean,
    val memoryEntriesCount: Int = 0,
    val databaseEntriesCount: Int = 0,
    val memoryUsagePercent: Int = 0,
    val needsCleanup: Boolean = false
)

// ✅ ROOM ENTITIES
@Entity(
    tableName = "cache",
    indices = [Index(value = ["key"], unique = true)]
)
data class CacheEntity(
    @PrimaryKey val key: String,
    @ColumnInfo(name = "data") val data: String,
    @ColumnInfo(name = "expires_at") val expiresAt: Long,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
)

@Dao
interface CacheDao {
    @Query("SELECT * FROM cache WHERE key = :key AND expires_at > :currentTime LIMIT 1")
    suspend fun getCache(key: String, currentTime: Long = System.currentTimeMillis()): CacheEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCache(cache: CacheEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCacheBatch(caches: List<CacheEntity>)

    @Query("DELETE FROM cache WHERE expires_at < :currentTime")
    suspend fun deleteExpiredCache(currentTime: Long)

    @Query("DELETE FROM cache")
    suspend fun deleteAllCache()

    @Query("SELECT COUNT(*) FROM cache")
    suspend fun getCacheCount(): Int

    @Query("DELETE FROM cache WHERE key = :key")
    suspend fun deleteCacheByKey(key: String)
}

// ✅ DATABASE
@Database(
    entities = [CacheEntity::class],
    version = 3,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class CORDatabase : RoomDatabase() {
    abstract fun cacheDao(): CacheDao

    companion object {
        @Volatile
        private var INSTANCE: CORDatabase? = null

        fun getInstance(context: android.content.Context): CORDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    CORDatabase::class.java,
                    "cor_database"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}

// ✅ TYPE CONVERTERS
class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): java.util.Date? {
        return value?.let { java.util.Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: java.util.Date?): Long? {
        return date?.time
    }
}