package bugarin.t.comando.ui.components

import android.content.Context
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import bugarin.t.comando.ui.utils.rememberLocationPermissionState // ✅ Usa a versão refatorada do utilitário de permissão
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun PermissionHandler(
    // ❌ REMOVIDO: O Composable não deve depender diretamente do LocationManager.
    // A lógica de permissão agora é comunicada ao ViewModel.
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val localizationViewModel: LocalizationViewModel = hiltViewModel()

    // O rememberLocationPermissionState agora gerencia o estado da permissão de forma isolada e robusta.
    val permissionState = rememberLocationPermissionState { isGranted ->
        // ✅ ATUALIZADO: Informa o ViewModel sobre o resultado da permissão.
        // O ViewModel então decidirá se deve iniciar o LocationManager.
        localizationViewModel.onLocationPermissionResult(isGranted)
    }

    // Lógica para mostrar a tela de explicação de permissão apenas uma vez.
    var rationaleShown by remember {
        mutableStateOf(
            context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                .getBoolean("rationale_shown", false)
        )
    }

    fun markRationaleAsShown() {
        rationaleShown = true
        context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("rationale_shown", true)
            .apply()
    }

    // Lógica de exibição
    when {
        // 1. Se a permissão já está concedida, mostra o conteúdo do app.
        permissionState.hasPermission -> {
            content()
        }
        // 2. Se a tela de explicação já foi mostrada (usuário já decidiu), mostra o conteúdo.
        // O app funcionará sem localização se o usuário negou anteriormente.
        rationaleShown -> {
            content()
        }
        // 3. Se não tem permissão e a tela de explicação nunca foi mostrada, exibe-a.
        else -> {
            LocationPermissionRequest(
                onRequestPermission = {
                    markRationaleAsShown()
                    permissionState.launchPermissionRequest() // Lança o pedido de permissão do sistema
                },
                onDismiss = {
                    markRationaleAsShown() // Marca como mostrado mesmo se o usuário dispensar
                },
                localizationViewModel = localizationViewModel
            )
        }
    }
}

@Composable
private fun LocationPermissionRequest(
    onRequestPermission: () -> Unit,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .systemBarsPadding(),
            contentAlignment = Alignment.Center
        ) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = null,
                        modifier = Modifier.size(56.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = localizationViewModel.getString("permission_location_title"),
                        style = MaterialTheme.typography.headlineSmall,
                        textAlign = TextAlign.Center
                    )
                    Text(
                        text = localizationViewModel.getString("permission_location_description"),
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        PermissionBenefit(localizationViewModel.getString("permission_benefit_map"))
                        PermissionBenefit(localizationViewModel.getString("permission_benefit_cameras"))
                        PermissionBenefit(localizationViewModel.getString("permission_benefit_alerts"))
                        PermissionBenefit(localizationViewModel.getString("permission_benefit_support"))
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(
                        onClick = onRequestPermission,
                        modifier = Modifier.fillMaxWidth().height(50.dp)
                    ) {
                        Text(localizationViewModel.getString("permission_allow"))
                    }
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(localizationViewModel.getString("permission_continue_without"))
                    }
                }
            }
        }
    }
}

@Composable
private fun PermissionBenefit(text: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top
    ) {
        Text(
            text = "•",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(end = 8.dp)
        )
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}