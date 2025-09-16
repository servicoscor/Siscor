package bugarin.t.comando.ui.utils

import bugarin.t.comando.data.Mappable
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.LatLngBounds
import com.google.maps.android.compose.CameraPositionState

/**
 * Função de zoom genérica que funciona para qualquer lista de itens "Mappable".
 * Esta versão é uma 'suspend' function para melhor integração com coroutines.
 */
suspend fun <T : Mappable> zoomToCommunity( // ✅ MUDANÇA: 'suspend' e remove o parâmetro CoroutineScope
    communityToFilter: String,
    allCommunitiesIdentifier: String,
    items: List<T>,
    cameraPositionState: CameraPositionState
) {
    val itemsToZoom = if (communityToFilter == allCommunitiesIdentifier) {
        items
    } else {
        items.filter { it.loc == communityToFilter }
    }

    if (itemsToZoom.isEmpty()) return

    if (itemsToZoom.size == 1) {
        itemsToZoom.first().coordinate?.let {
            cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(it, 16f))
        }
    } else {
        val boundsBuilder = LatLngBounds.builder()
        var includedPoints = 0
        itemsToZoom.forEach { item ->
            item.coordinate?.let {
                boundsBuilder.include(it)
                includedPoints++
            }
        }
        if (includedPoints > 0) {
            try {
                val bounds = boundsBuilder.build()
                cameraPositionState.animate(CameraUpdateFactory.newLatLngBounds(bounds, 100))
            } catch (e: IllegalStateException) {
                // Fallback se os pontos forem muito próximos
                itemsToZoom.first().coordinate?.let {
                    cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(it, 14f))
                }
            }
        }
    }
}