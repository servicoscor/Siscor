package bugarin.t.comando.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver

/**
 * ✅ RECOMENDADO: Classe de estado dedicada para clareza e escalabilidade.
 * Contém todo o estado relevante da permissão.
 */
data class LocationPermissionState(
    val hasPermission: Boolean,
    val hasFineLocationPermission: Boolean,
    val hasCoarseLocationPermission: Boolean
)

/**
 * Composable que gerencia o estado e o pedido de permissão de localização de forma idiomática.
 * Toda a lógica é autocontida, sem singletons globais.
 *
 * @param onPermissionResult Callback invocado com o novo estado após o usuário responder ao pedido.
 * @return Um par contendo o estado atual da permissão e uma função para lançar o pedido.
 */
@Composable
fun rememberLocationPermissionState(
    onPermissionResult: (LocationPermissionState) -> Unit = {}
): Pair<LocationPermissionState, () -> Unit> {

    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    // O estado agora é local e gerenciado pelo 'remember'.
    var state by remember {
        mutableStateOf(context.getCurrentPermissionState())
    }

    // Observador de ciclo de vida para atualizar a permissão quando o app volta ao primeiro plano.
    DisposableEffect(lifecycleOwner, context) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                state = context.getCurrentPermissionState()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) {
        // Após o launcher, atualiza o estado local diretamente.
        state = context.getCurrentPermissionState()
        onPermissionResult(state)
    }

    val launchRequest: () -> Unit = {
        launcher.launch(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        )
    }

    return Pair(state, launchRequest)
}

/**
 * Função utilitária privada para obter o estado atual das permissões a partir do contexto.
 */
private fun Context.getCurrentPermissionState(): LocationPermissionState {
    val hasFine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    val hasCoarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    return LocationPermissionState(
        hasPermission = hasFine || hasCoarse,
        hasFineLocationPermission = hasFine,
        hasCoarseLocationPermission = hasCoarse
    )
}

/**
 * Extensão pública para uma verificação simples e única.
 */
