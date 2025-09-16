package bugarin.t.comando.ui.theme // Movido para o pacote 'theme' para melhor organização

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * ✅ ARQUITETURA: Um componente de Card base, reutilizável e tematizável.
 * Ele fornece um fundo com gradiente e borda, permitindo que o conteúdo
 * seja customizado por quem o utiliza.
 *
 * @param modifier O modifier a ser aplicado ao Card.
 * @param gradient O gradiente a ser usado no fundo. Por padrão, usa um gradiente
 * baseado nas cores primárias do tema.
 * @param onClick Uma ação opcional a ser executada quando o card é clicado.
 * @param content O conteúdo a ser exibido dentro do card.
 */
@Composable
fun BaseCard(
    modifier: Modifier = Modifier,
    gradient: Brush = cardGradient(), // Usa o gradiente padrão do tema
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    val cardModifier = modifier.then(
        if (onClick != null) Modifier.clickable { onClick() } else Modifier
    )

    Card(
        modifier = cardModifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.Transparent // O fundo é aplicado manualmente
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = gradient,
                    shape = RoundedCornerShape(16.dp)
                )
                .border(
                    width = 1.dp,
                    // ✅ TEMATIZAÇÃO: A cor da borda agora é baseada na cor do conteúdo sobre o fundo primário.
                    color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.15f),
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            // O conteúdo específico de cada card é inserido aqui dentro de uma Column
            Column {
                content()
            }
        }
    }
}

/**
 * ✅ TEMATIZAÇÃO: Uma função Composable que cria o gradiente padrão para os cards
 * usando as cores do tema atual.
 */
@Composable
fun cardGradient(): Brush {
    return Brush.verticalGradient(
        colors = listOf(
            MaterialTheme.colorScheme.primary.copy(alpha = 0.9f),
            MaterialTheme.colorScheme.secondary.copy(alpha = 0.9f)
        )
    )
}