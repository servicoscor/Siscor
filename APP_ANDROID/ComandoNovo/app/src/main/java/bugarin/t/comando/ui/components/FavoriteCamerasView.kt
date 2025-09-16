package bugarin.t.comando.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import bugarin.t.comando.data.Camera
import bugarin.t.comando.viewmodel.LocalizationViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoriteCamerasView(
    allCameras: List<Camera>,
    favoriteCameraIds: Set<String>,
    onDismiss: () -> Unit,
    onCameraClick: (Camera) -> Unit,
    onFavoriteToggle: (String) -> Unit,
    localizationViewModel: LocalizationViewModel
) {

    val favoriteCameras = remember(allCameras, favoriteCameraIds) {
        allCameras.filter { favoriteCameraIds.contains(it.id) }
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(localizationViewModel.getString("favorite_cameras")) },
                    navigationIcon = {
                        IconButton(onClick = onDismiss) {
                            Icon(Icons.Default.ArrowBack, contentDescription = localizationViewModel.getString("back"))
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                )
            }
        ) { paddingValues ->
            if (favoriteCameras.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize().padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    EmptyStateView(
                        icon = Icons.Default.Star, // Trocar string por ícone
                        message = localizationViewModel.getString("no_favorite_cameras")
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(paddingValues),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(favoriteCameras, key = { it.id }) { camera ->
                        FavoriteCameraItem(
                            camera = camera,
                            onCameraClick = { onCameraClick(camera) },
                            onFavoriteToggle = { onFavoriteToggle(camera.id) }
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FavoriteCameraItem(
    camera: Camera,
    onCameraClick: () -> Unit,
    onFavoriteToggle: () -> Unit
) {
    Card(
        onClick = onCameraClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    text = camera.nome ?: "Câmara sem nome",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold
                )
                camera.apiId?.let {
                    Text(
                        text = "ID: $it",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            IconButton(onClick = onFavoriteToggle) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = "Remover dos Favoritos",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}