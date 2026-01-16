@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.screens

import android.content.Context
import android.content.Intent
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import bugarin.t.comando.data.Interdicao
import bugarin.t.comando.viewmodel.InterdicoesViewModel
import bugarin.t.comando.viewmodel.LocalizationViewModel

// ✅ ARQUITETURA: A UI agora é um Composable puro que recebe o ViewModel.
@Composable
fun InterdicoesView(
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel,
    viewModel: InterdicoesViewModel
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var searchText by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        viewModel.loadInterdicoes()
    }

    val interdicoesFiltradas = remember(uiState.interdicoes, searchText) {
        if (searchText.isBlank()) {
            uiState.interdicoes
        } else {
            uiState.interdicoes.filter {
                (it.via ?: "").contains(searchText, true) || (it.nor ?: "").contains(searchText, true)
            }
        }
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Scaffold(
            topBar = {
                HeaderSectionInterdicoes(
                    searchText = searchText,
                    onSearchTextChange = { searchText = it },
                    onShareClick = {
                        shareContent(interdicoesFiltradas, context, localizationViewModel)
                    },
                    onDismiss = onDismiss,
                    localizationViewModel = localizationViewModel,
                    hasInterdicoes = uiState.interdicoes.isNotEmpty()
                )
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
            ) {
                when {
                    uiState.isLoading -> LoadingState(localizationViewModel)
                    interdicoesFiltradas.isEmpty() -> EmptyState(searchText.isNotEmpty(), localizationViewModel)
                    else -> InterdicoesListView(interdicoesFiltradas, localizationViewModel)
                }
            }
        }
    }
}


@Composable
private fun HeaderSectionInterdicoes(
    searchText: String,
    onSearchTextChange: (String) -> Unit,
    onShareClick: () -> Unit,
    onDismiss: () -> Unit,
    localizationViewModel: LocalizationViewModel,
    hasInterdicoes: Boolean
) {
    Surface(shadowElevation = 4.dp) {
        Column(
            modifier = Modifier.statusBarsPadding().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = localizationViewModel.getString("scheduled_interdictions"),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                if (hasInterdicoes) {
                    IconButton(onClick = onShareClick) {
                        Icon(Icons.Default.Share, localizationViewModel.getString("share_list"))
                    }
                }
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, localizationViewModel.getString("close"))
                }
            }

            if (hasInterdicoes) {
                OutlinedTextField(
                    value = searchText,
                    onValueChange = onSearchTextChange,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text(localizationViewModel.getString("search_interdictions")) },
                    leadingIcon = { Icon(Icons.Default.Search, null) },
                    trailingIcon = {
                        if (searchText.isNotEmpty()) {
                            IconButton(onClick = { onSearchTextChange("") }) {
                                Icon(Icons.Default.Clear, localizationViewModel.getString("clear"))
                            }
                        }
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp)
                )
            }
        }
    }
}

@Composable
private fun InterdicoesListView(interdicoes: List<Interdicao>, localizationViewModel: LocalizationViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        itemsIndexed(interdicoes, key = { _, item -> item.id ?: item.hashCode() }) { index, interdicao ->
            InterdicaoCard(interdicao, index + 1, localizationViewModel)
        }
    }
}

@Composable
private fun InterdicaoCard(interdicao: Interdicao, index: Int, localizationViewModel: LocalizationViewModel) {
    var isExpanded by remember { mutableStateOf(false) }
    val rawText = interdicao.nor ?: interdicao.via ?: ""
    val formattedText = remember(rawText) { formatInterdicaoText(rawText) }
    val paragraphs = remember(formattedText) {
        formattedText.split("\n")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
    }

    Card(elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)) {
        Column(
            modifier = Modifier.padding(16.dp).animateContentSize(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(32.dp).background(MaterialTheme.colorScheme.primary, CircleShape)
                ) {
                    Text(index.toString(), fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onPrimary)
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(extractTitle(interdicao), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    interdicao.poli?.let { Text(it, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Medium) }
                }
                if (formattedText.length > 120) { // Limite para mostrar botão de expandir
                    IconButton(onClick = { isExpanded = !isExpanded }) {
                        Icon(if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore, null)
                    }
                }
            }

            interdicao.reg?.let {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Default.Schedule, null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            AnimatedVisibility(visible = isExpanded || formattedText.length <= 120) {
                Column(
                    modifier = Modifier.padding(top = 4.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    paragraphs.forEach { paragraph ->
                        Text(
                            text = paragraph,
                            style = MaterialTheme.typography.bodyMedium.copy(lineHeight = 20.sp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LoadingState(localizationViewModel: LocalizationViewModel) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            CircularProgressIndicator()
            Text(localizationViewModel.getString("loading_interdictions"))
        }
    }
}

@Composable
private fun EmptyState(isSearching: Boolean, localizationViewModel: LocalizationViewModel) {
    Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            val icon = if (isSearching) Icons.Default.SearchOff else Icons.Default.CheckCircle
            val text = if (isSearching) localizationViewModel.getString("no_results_found") else localizationViewModel.getString("no_interdictions")
            Icon(icon, null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f))
            Text(text, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// --- Funções Auxiliares ---
private fun extractTitle(interdicao: Interdicao): String {
    // Lógica para extrair um título significativo da descrição.
    val text = interdicao.via ?: interdicao.nor ?: return "Interdição"
    val keywords = listOf("Túnel", "Ponte", "Elevado", "Viaduto", "Av.", "Avenida", "Rua", "Estrada")
    val keywordFound = keywords.firstOrNull { text.contains(it, ignoreCase = true) }

    return if (keywordFound != null) {
        val startIndex = text.indexOf(keywordFound, ignoreCase = true)
        text.substring(startIndex).split(",")[0].trim()
    } else {
        text.take(40).trim()
    }
}

private fun shareContent(interdicoes: List<Interdicao>, context: Context, localizationViewModel: LocalizationViewModel) {
    val title = localizationViewModel.getString("scheduled_interdictions")
    val shareText = interdicoes.joinToString("\n\n") {
        val via = it.via ?: it.nor ?: ""
        val reg = it.reg ?: ""
        "- $via ($reg)"
    }
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_SUBJECT, title)
        putExtra(Intent.EXTRA_TEXT, "$title\n\n$shareText")
    }
    context.startActivity(Intent.createChooser(intent, localizationViewModel.getString("share")))
}

// ❌ REMOVIDO: Funções de tradução hardcoded. A UI deve usar chaves do sistema de strings.
// O backend ou repository deveria idealmente fornecer dados mais estruturados (ex: enums, chaves de tradução).
// Para este caso, a UI simplesmente exibirá os dados como eles vêm ("Programada", "Segunda"),
// e o app deve ter as traduções correspondentes em seus arquivos de strings.xml.


private fun formatInterdicaoText(text: String): String {
    if (text.isBlank()) return text

    var formatted = text.trim()
    formatted = formatted.replace(Regex("^\\s*\\d+\\s*;\\s*"), "")
    formatted = formatted.replace("jumpline", "\n", ignoreCase = true)
    formatted = formatted.replace("jump_line", "\n", ignoreCase = true)
    formatted = formatted.replace(";", "\n")
    formatted = formatted.replace(Regex("[ \\t]{2,}"), " ")
    val urlRegex = Regex("(https?://|www\\.|\\b[a-z0-9.-]+\\.[a-z]{2,})(/\\S*)?", RegexOption.IGNORE_CASE)

    return formatted
        .split("\n")
        .map { it.trim() }
        .filter { it.isNotEmpty() && !urlRegex.containsMatchIn(it) }
        .joinToString("\n")
}
