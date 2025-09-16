package bugarin.t.comando.ui.utils

import android.util.Log
import androidx.annotation.DrawableRes
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import coil.compose.rememberAsyncImagePainter
import coil.request.ImageRequest
import coil.size.Size

/**
 * ✅ SIMPLIFICADO: Carrega um Painter de forma segura a partir do nome do recurso.
 * Retorna nulo se o recurso não for encontrado, sem a sobrecarga de verificar o tamanho.
 */
@Composable
fun painterResourceOrNull(resourceName: String): Painter? {
    val context = LocalContext.current
    val resourceId = remember(resourceName) {
        context.resources.getIdentifier(
            resourceName,
            "drawable",
            context.packageName
        )
    }
    return if (resourceId != 0) painterResource(id = resourceId) else null
}

/**
 * ✅ SIMPLIFICADO: Wrapper seguro para painterResource que retorna nulo se o ID for inválido.
 * A verificação de tamanho foi removida em favor da gestão de assets.
 * Use esta função para ícones e imagens de tamanho adequado na pasta 'drawable'.
 */
@Composable
fun painterResourceOrNull(@DrawableRes id: Int?): Painter? {
    if (id == null || id == 0) return null

    // Em vez de try-catch, verificamos se o recurso existe antes de tentar carregá-lo
    val context = LocalContext.current
    val resourceExists = remember(id) {
        try {
            context.resources.getResourceName(id)
            true
        } catch (e: Exception) {
            Log.e("painterResourceOrNull", "Recurso não encontrado com ID: $id", e)
            false
        }
    }

    return if (resourceExists) {
        painterResource(id = id)
    } else {
        null
    }
}

/**
 * ✅ MANTIDO: Função otimizada para carregar drawables com Coil.
 * Use esta função explicitamente quando você souber que um drawable é muito grande
 * ou quando quiser os benefícios do Coil (caching, crossfade, etc.).
 */
@Composable
fun painterResourceWithCoil(@DrawableRes id: Int): Painter {
    return rememberAsyncImagePainter(
        model = ImageRequest.Builder(LocalContext.current)
            .data(id)
            .size(Size.ORIGINAL)
            .allowHardware(true)
            .memoryCacheKey("res_$id") // Chave de cache para evitar recarregamentos
            .crossfade(true)
            .build()
    )
}

/**
 * Composable que exibe uma imagem de forma segura, com um fallback.
 */
@Composable
fun SafeImage(
    @DrawableRes resourceId: Int,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    fallback: @Composable () -> Unit = {}
) {
    val painter = painterResourceOrNull(resourceId)
    if (painter != null) {
        Image(
            painter = painter,
            contentDescription = contentDescription,
            modifier = modifier
        )
    } else {
        fallback()
    }
}

/**
 * Composable que exibe uma imagem com um fallback para outro recurso.
 */
@Composable
fun ImageWithFallback(
    @DrawableRes resourceId: Int,
    @DrawableRes fallbackResourceId: Int,
    contentDescription: String?,
    modifier: Modifier = Modifier
) {
    val painter = painterResourceOrNull(resourceId) ?: painterResourceOrNull(fallbackResourceId)
    if (painter != null) {
        Image(
            painter = painter,
            contentDescription = contentDescription,
            modifier = modifier
        )
    }
}