package bugarin.t.comando.ui.components

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import bugarin.t.comando.ui.theme.cardGradient
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun BotoesFinaisView(
    onUnidadesSaudeClick: () -> Unit,
    onPontosTuristicosClick: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val context = LocalContext.current
    var showSocialMediaDialog by remember { mutableStateOf(false) }

    // Função auxiliar para encontrar Activity
    fun Context.findActivity(): Activity? {
        var currentContext = this
        while (currentContext is ContextWrapper) {
            if (currentContext is Activity) {
                return currentContext
            }
            currentContext = currentContext.baseContext
        }
        return null
    }

    // Função para ligar para a Defesa Civil
    fun ligarDefesaCivil() {
        val intent = Intent(Intent.ACTION_DIAL).apply {
            data = Uri.parse("tel:199")
        }

        val activity = context.findActivity()
        if (activity != null) {
            activity.startActivity(intent)
        } else {
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        }
    }

    // Função para abrir Instagram
    fun abrirInstagram() {
        val instagramAppUri = Uri.parse("instagram://user?username=centrooperacoesrio")
        val instagramWebUri = Uri.parse("https://www.instagram.com/centrooperacoesrio/")

        val activity = context.findActivity()

        try {
            val appIntent = Intent(Intent.ACTION_VIEW, instagramAppUri).apply {
                setPackage("com.instagram.android")
            }

            if (activity != null) {
                activity.startActivity(appIntent)
            } else {
                appIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(appIntent)
            }
        } catch (e: Exception) {
            val webIntent = Intent(Intent.ACTION_VIEW, instagramWebUri)

            if (activity != null) {
                activity.startActivity(webIntent)
            } else {
                webIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(webIntent)
            }
        }
    }

    // Função para abrir Twitter/X
    fun abrirTwitter() {
        val twitterAppUri = Uri.parse("twitter://user?screen_name=OperacoesRio")
        val twitterWebUri = Uri.parse("https://twitter.com/OperacoesRio")

        val activity = context.findActivity()

        try {
            val appIntent = Intent(Intent.ACTION_VIEW, twitterAppUri).apply {
                setPackage("com.twitter.android")
            }

            if (activity != null) {
                activity.startActivity(appIntent)
            } else {
                appIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(appIntent)
            }
        } catch (e: Exception) {
            val webIntent = Intent(Intent.ACTION_VIEW, twitterWebUri)

            if (activity != null) {
                activity.startActivity(webIntent)
            } else {
                webIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(webIntent)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Primeira coluna
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                FuncaoButton(
                    iconVector = Icons.Default.Phone,
                    labelText = localizationViewModel.getString("call_civil_defense"),
                    onClick = ::ligarDefesaCivil
                )

                FuncaoButton(
                    iconVector = Icons.Default.LocalHospital,
                    labelText = localizationViewModel.getString("health_units"),
                    onClick = onUnidadesSaudeClick
                )
            }

            // Segunda coluna
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                FuncaoButton(
                    iconVector = Icons.Default.Landscape,
                    labelText = localizationViewModel.getString("tourist_spots"),
                    onClick = onPontosTuristicosClick
                )

                FuncaoButton(
                    iconVector = Icons.Default.People,
                    labelText = localizationViewModel.getString("social_networks"),
                    onClick = { showSocialMediaDialog = true }
                )
            }
        }
    }

    // Dialog de Redes Sociais
    if (showSocialMediaDialog) {
        AlertDialog(
            onDismissRequest = { showSocialMediaDialog = false },
            title = {
                Text(localizationViewModel.getString("social_networks"))
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                        onClick = {
                            abrirInstagram()
                            showSocialMediaDialog = false
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            Icons.Default.PhotoCamera,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text("Instagram")
                    }

                    OutlinedButton(
                        onClick = {
                            abrirTwitter()
                            showSocialMediaDialog = false
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            Icons.Default.AlternateEmail,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text("Twitter/X")
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showSocialMediaDialog = false }) {
                    Text(localizationViewModel.getString("cancel"))
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FuncaoButton(
    iconVector: ImageVector,
    labelText: String,
    onClick: () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val haptic = LocalHapticFeedback.current

    val contentColor = MaterialTheme.colorScheme.onPrimary

    Card(
        onClick = {
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            onClick()
        },
        interactionSource = interactionSource,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .scale(if (isPressed) 0.96f else 1f)
            .graphicsLayer {
                rotationX = if (isPressed) 2f else 0f
            },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (isPressed) 4.dp else 8.dp
        )
    ) {
        Box(
            modifier = Modifier
                .background(
                    brush = cardGradient,
                    shape = RoundedCornerShape(16.dp)
                )
                .border(
                    width = 1.dp,
                    color = contentColor.copy(alpha = 0.15f),
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(12.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    iconVector,
                    contentDescription = null,
                    modifier = Modifier.size(40.dp),
                    tint = contentColor
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = labelText,
                    style = MaterialTheme.typography.titleMedium.copy(
                        shadow = Shadow(
                            color = Color.Black.copy(alpha = 0.3f),
                            offset = Offset(0f, 2f),
                            blurRadius = 2f
                        )
                    ),
                    fontWeight = FontWeight.Bold,
                    color = contentColor,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Efeito de brilho no topo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp)
                    .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                    .background(
                        brush = Brush.verticalGradient(
                            listOf(
                                contentColor.copy(alpha = 0.1f),
                                Color.Transparent
                            )
                        )
                    )
            )
        }
    }
}