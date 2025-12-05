package bugarin.t.comando.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.layout.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import bugarin.t.comando.ui.utils.painterResourceOrNull
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun EstagioView(
    currentStage: Int,
    localizationViewModel: LocalizationViewModel
) {
    var selectedDetail by remember { mutableStateOf<Int?>(null) }
    val languageCode by localizationViewModel.currentLanguage.collectAsState()
    val contentColor = Color.White // Cor intencional para alto contraste no fundo escuro.

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp)
    ) {
        Text(
            text = localizationViewModel.getString("city_in"),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = contentColor
        )

        EstagioImage(
            stage = currentStage,
            languageCode = languageCode,
            modifier = Modifier.height(180.dp).padding(vertical = 20.dp)
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .background(Color.Black.copy(alpha = 0.2f), RoundedCornerShape(20.dp))
                .border(1.dp, contentColor.copy(alpha = 0.1f), RoundedCornerShape(20.dp))
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ✅ LAYOUT: Removida a altura fixa para permitir que os troféus se adaptem à largura.
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (stage in 1..5) {
                    PlayStationTrophy(
                        stage = stage,
                        currentStage = currentStage,
                        isSelected = selectedDetail == stage,
                        onTap = { selectedDetail = if (selectedDetail == stage) null else stage },
                        languageCode = languageCode,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            AnimatedVisibility(
                visible = selectedDetail != null,
                enter = expandVertically(animationSpec = spring(stiffness = Spring.StiffnessMedium)) + fadeIn(),
                exit = shrinkVertically(animationSpec = spring(stiffness = Spring.StiffnessMedium)) + fadeOut()
            ) {
                selectedDetail?.let { stage ->
                    TrophyDetailView(stage = stage, localizationViewModel = localizationViewModel, contentColor = contentColor)
                }
            }
        }
    }
}

@Composable
private fun EstagioImage(stage: Int, languageCode: String, modifier: Modifier = Modifier) {
    val imageName = getImageName(stage, languageCode)
    val painter = painterResourceOrNull(imageName)

    if (painter != null) {
        Image(painter, "Stage $stage", modifier, contentScale = ContentScale.Fit)
    } else {
        Icon(Icons.Filled.Shield, "Stage $stage", modifier, tint = colorForStage(stage))
    }
}

@Composable
private fun PlayStationTrophy(
    stage: Int, currentStage: Int, isSelected: Boolean, onTap: () -> Unit,
    languageCode: String, modifier: Modifier = Modifier
) {
    val stageColor = if (stage > currentStage) MaterialTheme.colorScheme.outline else colorForStage(stage)
    val scale by animateFloatAsState(
        targetValue = if (stage == currentStage) 1.1f else 1.0f,
        animationSpec = spring(dampingRatio = 0.4f, stiffness = Spring.StiffnessMedium),
        label = "TrophyScale"
    )

    IconButton(
        onClick = onTap,
        modifier = modifier.aspectRatio(1f).scale(scale)
    ) {
        Box(contentAlignment = Alignment.Center) {
            val borderColor = when {
                isSelected -> MaterialTheme.colorScheme.primary
                stage == currentStage -> stageColor
                else -> Color.White.copy(alpha = 0.2f)
            }
            // Borda
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .border(width = if (isSelected || stage == currentStage) 2.dp else 1.dp, color = borderColor, shape = CircleShape)
            )
            // Imagem
            val painter = painterResourceOrNull(getImageName(stage, languageCode))
            if (painter != null) {
                Image(
                    painter = painter, contentDescription = "Stage $stage",
                    modifier = Modifier.fillMaxSize(0.75f).alpha(if (stage <= currentStage) 1f else 0.4f),
                    contentScale = ContentScale.Fit,
                    colorFilter = if (stage > currentStage) ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) }) else null
                )
            }
        }
    }
}

@Composable
private fun TrophyDetailView(stage: Int, localizationViewModel: LocalizationViewModel, contentColor: Color) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
            .background(Color.Black.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = localizationViewModel.getString("stage_${stage}_title").uppercase(),
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = colorForStage(stage)
        )
        Divider(color = contentColor.copy(alpha = 0.2f))
        Text(
            text = localizationViewModel.getString("stage_${stage}_when"),
            style = MaterialTheme.typography.bodyMedium,
            color = contentColor.copy(alpha = 0.9f)
        )
        Text(
            text = localizationViewModel.getString("stage_${stage}_impact"),
            style = MaterialTheme.typography.bodyMedium,
            color = contentColor.copy(alpha = 0.9f)
        )
    }
}

private fun getImageName(stage: Int, languageCode: String): String {
    val langSuffix = when (languageCode) {
        "pt" -> ""; "en" -> "_en"; "es" -> "_es"; "fr" -> "_fr"; "zh" -> "_zh"
        else -> ""
    }
    return "selo_cidade_estagio_0$stage$langSuffix"
}

@Composable
private fun colorForStage(stage: Int): Color = when (stage) {
    // ✅ CORES DOS ESTÁGIOS conforme documentação
    1 -> Color(0xFF4CAF50) // Verde
    2 -> Color(0xFFFDD835) // Amarelo (ajustado de FFC107 para FDD835)
    3 -> Color(0xFFFF9800) // Laranja
    4 -> Color(0xFFF44336) // Vermelho
    5 -> Color(0xFF9C27B0) // Roxo
    else -> MaterialTheme.colorScheme.outline
}