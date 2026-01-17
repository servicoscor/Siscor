@file:OptIn(ExperimentalMaterial3Api::class)

package bugarin.t.comando.ui.components

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import bugarin.t.comando.viewmodel.LocalizationViewModel

@Composable
fun FullScreenCarnavalView(
    onNavigateBack: () -> Unit,
    localizationViewModel: LocalizationViewModel
) {
    val context = LocalContext.current
    val carnavalUrl = "https://carnaval2026.cor.rio/"
    var openFailed by remember { mutableStateOf(false) }
    var launchedOnce by remember { mutableStateOf(false) }

    BackHandler { onNavigateBack() }

    LaunchedEffect(Unit) {
        if (!launchedOnce) {
            launchedOnce = true
            val opened = tryOpenCustomTab(context, carnavalUrl)
            if (opened) {
                onNavigateBack()
            } else {
                openFailed = true
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Icon(Icons.Default.Celebration, null, tint = MaterialTheme.colorScheme.primary)
                        Text(
                            text = localizationViewModel.getString("carnival_2026_title"),
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {
                        val opened = tryOpenCustomTab(context, carnavalUrl)
                        if (opened) {
                            onNavigateBack()
                        } else {
                            openFailed = true
                        }
                    }) {
                        Icon(Icons.Default.Refresh, localizationViewModel.getString("refresh"))
                    }
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.Close, localizationViewModel.getString("close"))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.surface
    ) { paddingValues: PaddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.surface),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.padding(24.dp)
            ) {
                Icon(Icons.Default.OpenInBrowser, null, modifier = Modifier.size(32.dp))
                Text(localizationViewModel.getString("loading"))
                if (openFailed) {
                    Text(
                        text = localizationViewModel.getString("error_loading_data"),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Button(onClick = { openExternalBrowser(context, carnavalUrl) }) {
                    Text(text = "Abrir no navegador")
                }
            }
        }
    }
}

private fun tryOpenCustomTab(context: Context, url: String): Boolean {
    return runCatching {
        val customTabsIntent = CustomTabsIntent.Builder()
            .setShowTitle(true)
            .build()
        val activity = context.findActivity()
        if (activity != null) {
            customTabsIntent.launchUrl(activity, Uri.parse(url))
        } else {
            customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            customTabsIntent.launchUrl(context, Uri.parse(url))
        }
        true
    }.getOrElse { false }
}

private fun openExternalBrowser(context: Context, url: String) {
    runCatching {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        val activity = context.findActivity()
        if (activity != null) {
            activity.startActivity(intent)
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }
}

private fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}
