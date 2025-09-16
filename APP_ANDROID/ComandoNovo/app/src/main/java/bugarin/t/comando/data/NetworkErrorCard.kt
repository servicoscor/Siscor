package bugarin.t.comando.ui.components

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import bugarin.t.comando.viewmodel.LocalizationViewModel
import java.net.SocketTimeoutException
import java.net.UnknownHostException

@OptIn(ExperimentalAnimationApi::class)
@Composable
fun NetworkErrorCard(
    error: Exception,
    onRetry: () -> Unit,
    localizationViewModel: LocalizationViewModel,
    modifier: Modifier = Modifier
) {
    val errorInfo = getErrorInfo(error, localizationViewModel)

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.1f)
        ),
        border = CardDefaults.outlinedCardBorder()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Ícone animado
            AnimatedContent(
                targetState = errorInfo.icon,
                transitionSpec = {
                    fadeIn() with fadeOut()
                },
                label = "error_icon_animation"
            ) { icon ->
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.error
                )
            }

            // Título do erro
            Text(
                text = errorInfo.title,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center
            )

            // Descrição do erro
            Text(
                text = errorInfo.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            // Dica de solução
            errorInfo.hint?.let { hint ->
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lightbulb,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = hint,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            // Botão de retry
            Button(
                onClick = onRetry,
                shape = RoundedCornerShape(8.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = localizationViewModel.getString("try_again"))
            }
        }
    }
}

@Composable
fun InlineNetworkError(
    error: Exception,
    onRetry: () -> Unit,
    localizationViewModel: LocalizationViewModel,
    modifier: Modifier = Modifier
) {
    val errorInfo = getErrorInfo(error, localizationViewModel)

    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.1f),
        border = CardDefaults.outlinedCardBorder()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = errorInfo.icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(24.dp)
            )

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = errorInfo.title,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = errorInfo.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            IconButton(onClick = onRetry) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = localizationViewModel.getString("try_again"),
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

private data class ErrorInfo(
    val icon: ImageVector,
    val title: String,
    val description: String,
    val hint: String? = null
)

private fun getErrorInfo(
    error: Exception,
    localizationViewModel: LocalizationViewModel
): ErrorInfo {
    return when (error) {
        is UnknownHostException -> ErrorInfo(
            icon = Icons.Default.WifiOff,
            title = localizationViewModel.getString("no_internet_connection"),
            description = localizationViewModel.getString("check_internet_connection"),
            hint = localizationViewModel.getString("hint_check_wifi_mobile_data")
        )

        is SocketTimeoutException -> ErrorInfo(
            icon = Icons.Default.AccessTime,
            title = localizationViewModel.getString("connection_timeout"),
            description = localizationViewModel.getString("server_taking_too_long"),
            hint = localizationViewModel.getString("hint_try_better_connection")
        )

        is NoDataException -> ErrorInfo(
            icon = Icons.Default.CloudOff,
            title = localizationViewModel.getString("no_data_available"),
            description = localizationViewModel.getString("server_no_data"),
            hint = localizationViewModel.getString("hint_try_again_later")
        )

        else -> ErrorInfo(
            icon = Icons.Default.ErrorOutline,
            title = localizationViewModel.getString("error_occurred"),
            description = error.message ?: localizationViewModel.getString("unknown_error"),
            hint = null
        )
    }
}

// Exception customizada para quando não há dados
class NoDataException(message: String) : Exception(message)