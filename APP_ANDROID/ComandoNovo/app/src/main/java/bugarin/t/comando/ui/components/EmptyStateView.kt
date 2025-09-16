package bugarin.t.comando.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/**
 * Um componente reutilizável para exibir um estado vazio com um ícone e uma mensagem.
 */
@Composable
fun EmptyStateView(
    // ✅ ARQUITETURA: Recebe o ImageVector diretamente para maior segurança e simplicidade.
    icon: ImageVector,
    message: String,
    modifier: Modifier = Modifier,
    // ✅ TEMATIZAÇÃO: Permite a personalização da cor do conteúdo.
    contentColor: Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 40.dp, horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(56.dp),
            tint = contentColor.copy(alpha = 0.7f)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
            color = contentColor,
            textAlign = TextAlign.Center
        )
    }
}

// ❌ REMOVIDO: A função auxiliar 'getIconVector' não é mais necessária,
// pois o ImageVector é passado diretamente para o componente.