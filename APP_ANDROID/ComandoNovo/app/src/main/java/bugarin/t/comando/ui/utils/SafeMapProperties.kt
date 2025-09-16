package bugarin.t.comando.ui.utils

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapType
import com.google.maps.android.compose.MapUiSettings

/**
 * Creates safe MapProperties that NEVER enable MyLocation automatically
 * to avoid SecurityException when permission is not granted.
 */
@Composable
fun rememberSafeMapProperties(
    mapType: MapType = MapType.NORMAL,
    mapStyleOptions: MapStyleOptions? = null,
    isBuildingEnabled: Boolean = true,
    isIndoorEnabled: Boolean = false,
    isTrafficEnabled: Boolean = false,
    maxZoomLevel: Float = 21.0f,
    minZoomLevel: Float = 3.0f
): MapProperties {
    return remember(mapType, mapStyleOptions, isBuildingEnabled, isIndoorEnabled, isTrafficEnabled) {
        MapProperties(
            isBuildingEnabled = isBuildingEnabled,
            isIndoorEnabled = isIndoorEnabled,
            // ALWAYS FALSE - Never enable automatically
            isMyLocationEnabled = false,
            isTrafficEnabled = isTrafficEnabled,
            mapStyleOptions = mapStyleOptions,
            mapType = mapType,
            maxZoomPreference = maxZoomLevel,
            minZoomPreference = minZoomLevel
        )
    }
}

/**
 * Creates default MapUiSettings, disabling controls that might
 * interfere with the user experience.
 */
@Composable
fun rememberSafeMapUiSettings(
    isCompassEnabled: Boolean = false,
    isMapToolbarEnabled: Boolean = false,
    isMyLocationButtonEnabled: Boolean = false, // This parameter is kept for the remember key but is always set to false below.
    isRotationGesturesEnabled: Boolean = true,
    isScrollGesturesEnabled: Boolean = true,
    isScrollGesturesEnabledDuringRotateOrZoom: Boolean = true,
    isTiltGesturesEnabled: Boolean = true,
    isZoomControlsEnabled: Boolean = false,
    isZoomGesturesEnabled: Boolean = true
): MapUiSettings {
    return remember(
        isCompassEnabled,
        isMapToolbarEnabled,
        isMyLocationButtonEnabled,
        isRotationGesturesEnabled,
        isScrollGesturesEnabled,
        isScrollGesturesEnabledDuringRotateOrZoom,
        isTiltGesturesEnabled,
        isZoomControlsEnabled,
        isZoomGesturesEnabled
    ) {
        // CORRECTED: Pass parameters directly to the MapUiSettings constructor
        // instead of using a non-existent .copy() method.
        // Also corrected the parameter names (e.g., compassEnabled instead of isCompassEnabled).
        MapUiSettings(
            compassEnabled = isCompassEnabled,
            mapToolbarEnabled = isMapToolbarEnabled,
            // ALWAYS FALSE - Never show Google's MyLocation button
            myLocationButtonEnabled = false,
            rotationGesturesEnabled = isRotationGesturesEnabled,
            scrollGesturesEnabled = isScrollGesturesEnabled,
            scrollGesturesEnabledDuringRotateOrZoom = isScrollGesturesEnabledDuringRotateOrZoom,
            tiltGesturesEnabled = isTiltGesturesEnabled,
            zoomControlsEnabled = isZoomControlsEnabled,
            zoomGesturesEnabled = isZoomGesturesEnabled
        )
    }
}

/**
 * MapProperties specific for small views (cards).
 */
@Composable
fun rememberCardMapProperties(): MapProperties {
    return rememberSafeMapProperties(
        isBuildingEnabled = true,
        isIndoorEnabled = false,
        isTrafficEnabled = false
    )
}

/**
 * MapUiSettings specific for small views (cards).
 * Disables all interactive controls.
 */
@Composable
fun rememberCardMapUiSettings(): MapUiSettings {
    return rememberSafeMapUiSettings(
        isRotationGesturesEnabled = false,
        isScrollGesturesEnabled = false,
        isTiltGesturesEnabled = false,
        isZoomGesturesEnabled = false
    )
}

/**
 * MapProperties for fullscreen interactive maps.
 */
@Composable
fun rememberInteractiveMapProperties(): MapProperties {
    return rememberSafeMapProperties(
        isBuildingEnabled = true,
        isIndoorEnabled = false,
        isTrafficEnabled = false
    )
}

/**
 * MapUiSettings for fullscreen interactive maps.
 */
@Composable
fun rememberInteractiveMapUiSettings(): MapUiSettings {
    return rememberSafeMapUiSettings(
        isCompassEnabled = false,
        isRotationGesturesEnabled = true,
        isScrollGesturesEnabled = true,
        isTiltGesturesEnabled = true,
        isZoomGesturesEnabled = true,
        isZoomControlsEnabled = false
    )
}
