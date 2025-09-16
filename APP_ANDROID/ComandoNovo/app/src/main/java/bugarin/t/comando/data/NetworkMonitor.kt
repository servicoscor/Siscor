package bugarin.t.comando.utils

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NetworkMonitor @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    /**
     * Verifica se há conexão de rede disponível
     */
    fun isNetworkAvailable(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            capabilities?.let {
                it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                        it.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
                        it.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
            } ?: false
        } else {
            @Suppress("DEPRECATION")
            connectivityManager.activeNetworkInfo?.isConnected ?: false
        }
    }

    /**
     * Retorna o tipo de conexão atual
     */
    fun getConnectionType(): ConnectionType {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            return when {
                capabilities == null -> ConnectionType.NONE
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> ConnectionType.WIFI
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> ConnectionType.CELLULAR
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> ConnectionType.ETHERNET
                else -> ConnectionType.UNKNOWN
            }
        } else {
            @Suppress("DEPRECATION")
            return when (connectivityManager.activeNetworkInfo?.type) {
                ConnectivityManager.TYPE_WIFI -> ConnectionType.WIFI
                ConnectivityManager.TYPE_MOBILE -> ConnectionType.CELLULAR
                ConnectivityManager.TYPE_ETHERNET -> ConnectionType.ETHERNET
                null -> ConnectionType.NONE
                else -> ConnectionType.UNKNOWN
            }
        }
    }

    /**
     * Verifica se a conexão é medida (limitada)
     */
    fun isConnectionMetered(): Boolean {
        return connectivityManager.isActiveNetworkMetered
    }

    /**
     * Flow que emite mudanças no status da rede
     */
    val networkStatus: Flow<NetworkStatus> = callbackFlow {
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                val connectionType = when {
                    capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> ConnectionType.WIFI
                    capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> ConnectionType.CELLULAR
                    capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true -> ConnectionType.ETHERNET
                    else -> ConnectionType.UNKNOWN
                }
                trySend(NetworkStatus.Available(connectionType))
            }

            override fun onLost(network: Network) {
                trySend(NetworkStatus.Lost)
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                val connectionType = when {
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> ConnectionType.WIFI
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> ConnectionType.CELLULAR
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> ConnectionType.ETHERNET
                    else -> ConnectionType.UNKNOWN
                }
                trySend(NetworkStatus.Available(connectionType))
            }
        }

        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(networkRequest, networkCallback)

        // Emite o estado inicial
        trySend(
            if (isNetworkAvailable()) {
                NetworkStatus.Available(getConnectionType())
            } else {
                NetworkStatus.Lost
            }
        )

        awaitClose {
            connectivityManager.unregisterNetworkCallback(networkCallback)
        }
    }.distinctUntilChanged()
}

/**
 * Estados possíveis da rede
 */
sealed class NetworkStatus {
    data class Available(val type: ConnectionType) : NetworkStatus()
    object Lost : NetworkStatus()
}

/**
 * Tipos de conexão
 */
enum class ConnectionType {
    WIFI,
    CELLULAR,
    ETHERNET,
    UNKNOWN,
    NONE
}

/**
 * Extension functions úteis
 */
fun NetworkStatus.isAvailable() = this is NetworkStatus.Available
fun NetworkStatus.isLost() = this is NetworkStatus.Lost

fun NetworkStatus.Available.isWifi() = type == ConnectionType.WIFI
fun NetworkStatus.Available.isCellular() = type == ConnectionType.CELLULAR
fun NetworkStatus.Available.isEthernet() = type == ConnectionType.ETHERNET