package bugarin.t.comando.ui.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver

data class LocationPermissionState(
    val hasPermission: Boolean,
    val launchPermissionRequest: () -> Unit
)

@Composable
fun rememberLocationPermissionState(
    onPermissionResult: (Boolean) -> Unit = {}
): LocationPermissionState {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var permissionState by remember { mutableStateOf(context.hasLocationPermission()) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val isGranted = permissions.values.any { it }
        permissionState = isGranted
        onPermissionResult(isGranted)
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                permissionState = context.hasLocationPermission()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    return LocationPermissionState(
        hasPermission = permissionState,
        launchPermissionRequest = {
            permissionLauncher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION))
        }
    )
}

fun Context.hasLocationPermission(): Boolean {
    return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
}