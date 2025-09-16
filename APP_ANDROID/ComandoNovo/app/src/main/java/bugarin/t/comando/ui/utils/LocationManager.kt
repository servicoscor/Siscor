package bugarin.t.comando.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

// ✅ RECOMENDAÇÃO: Use @Inject no construtor se estiver usando Hilt.
// Isso permite que o Hilt forneça o contexto da aplicação automaticamente.
class LocationManager @Inject constructor(private val context: Context) {
    companion object {
        private const val TAG = "LocationManager"
        private const val LOCATION_INTERVAL = 10000L // 10 segundos
        private const val FASTEST_INTERVAL = 5000L // 5 segundos
    }

    private val fusedLocationClient: FusedLocationProviderClient by lazy {
        LocationServices.getFusedLocationProviderClient(context.applicationContext)
    }

    private val _location = MutableStateFlow<Location?>(null)
    val location: StateFlow<Location?> = _location.asStateFlow()

    private val _authorizationStatus = MutableStateFlow(AuthorizationStatus.NOT_DETERMINED)
    val authorizationStatus: StateFlow<AuthorizationStatus> = _authorizationStatus.asStateFlow()

    private var isUpdatingLocation = false

    private val locationRequest: LocationRequest by lazy {
        LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, LOCATION_INTERVAL).apply {
            setMinUpdateIntervalMillis(FASTEST_INTERVAL)
        }.build()
    }

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.lastLocation?.let { newLocation ->
                _location.value = newLocation
                Log.d(TAG, "📍 Localização atualizada: ${newLocation.latitude}, ${newLocation.longitude}")
            }
        }
    }

    // ❌ REMOVIDO: Bloco init que chamava checkLocationPermission() automaticamente.
    // A classe agora aguarda um comando para iniciar.

    /**
     * ✅ NOVO: Ponto de entrada principal. Verifica as permissões e inicia as atualizações.
     * Deve ser chamado pelo ViewModel quando a localização for necessária.
     */
    fun startLocationUpdates() {
        if (isUpdatingLocation) {
            Log.d(TAG, "Já estava atualizando a localização.")
            return
        }

        // Verifica a permissão no momento do início
        if (!context.hasLocationPermission()) {
            Log.w(TAG, "Permissão de localização negada. Não é possível iniciar.")
            _authorizationStatus.value = AuthorizationStatus.DENIED
            return
        }

        // Atualiza o status de autorização
        _authorizationStatus.value = if (context.hasFineLocationPermission()) {
            AuthorizationStatus.AUTHORIZED_ALWAYS
        } else {
            AuthorizationStatus.AUTHORIZED_WHEN_IN_USE
        }

        Log.d(TAG, "Iniciando atualizações de localização...")
        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
                .addOnSuccessListener {
                    isUpdatingLocation = true
                    Log.d(TAG, "✅ Solicitação de atualização de localização iniciada com sucesso.")
                }.addOnFailureListener { e ->
                    Log.e(TAG, "❌ Falha ao iniciar atualizações: ${e.message}")
                }
        } catch (e: SecurityException) {
            // Este catch é uma segurança extra, mas a verificação acima deve preveni-lo.
            Log.e(TAG, "SecurityException ao iniciar atualizações.", e)
            _authorizationStatus.value = AuthorizationStatus.DENIED
        }
    }

    fun stopLocationUpdates() {
        if (!isUpdatingLocation) return

        Log.d(TAG, "Parando atualizações de localização...")
        fusedLocationClient.removeLocationUpdates(locationCallback)
            .addOnCompleteListener {
                isUpdatingLocation = false
                Log.d(TAG, "✅ Atualizações de localização paradas.")
            }
    }
}

// Funções de extensão (assumindo que estão no mesmo arquivo ou acessíveis)
fun Context.hasLocationPermission(): Boolean {
    return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
}

fun Context.hasFineLocationPermission(): Boolean {
    return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
}

enum class AuthorizationStatus {
    NOT_DETERMINED,
    DENIED,
    AUTHORIZED_ALWAYS, // Fine location
    AUTHORIZED_WHEN_IN_USE // Coarse location
}