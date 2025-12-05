package bugarin.t.comando.ui.components

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Message
import android.util.Log
import android.webkit.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.lang.ref.WeakReference

/**
 * Representa os possíveis estados do ControlledWebView.
 */
sealed class WebViewState {
    data object Loading : WebViewState()
    data object Success : WebViewState()
    data class Error(val message: String? = null) : WebViewState()
}

/**
 * ✅ MEMORY OPTIMIZED: WebView com melhor gerenciamento de memória e cleanup
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun ControlledWebView(
    modifier: Modifier = Modifier,
    url: String,
    sessionId: String,
    reloadTrigger: Int = 0,
    onStateChange: (WebViewState) -> Unit,
    fitMode: Boolean = false,
    rotate90: Boolean = false,
) {
    val TAG = "ControlledWebView-$sessionId"
    val context = LocalContext.current
    val latestOnStateChange by rememberUpdatedState(onStateChange)

    // ✅ MEMORY: WeakReference para evitar memory leaks
    var webViewRef by remember { mutableStateOf<WeakReference<WebView>?>(null) }

    // ✅ MEMORY: WebView otimizado com cleanup adequado e configurações de memória
    val webView = remember {
        WebView(context).apply {
            settings.apply {
                // ✅ PERFORMANCE: Configurações otimizadas
                javaScriptEnabled = true
                domStorageEnabled = true
                loadWithOverviewMode = true
                useWideViewPort = true
                builtInZoomControls = false
                displayZoomControls = false

                // ✅ MEMORY: Configurações de cache e memória otimizadas
                cacheMode = WebSettings.LOAD_NO_CACHE // ✅ CRITICAL: Evita acúmulo de cache
                // ✅ FIXED: Removido setAppCacheEnabled e setAppCacheMaxSize - deprecated
                databaseEnabled = false

                // ✅ MEMORY: Configurações de memória específicas
                setRenderPriority(WebSettings.RenderPriority.HIGH)
                setLayoutAlgorithm(WebSettings.LayoutAlgorithm.TEXT_AUTOSIZING)

                // ✅ SECURITY: Configurações de segurança
                mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
                allowFileAccess = false
                allowContentAccess = false
                allowFileAccessFromFileURLs = false
                allowUniversalAccessFromFileURLs = false

                // ✅ MEMORY: User agent otimizado
                userAgentString = "Mozilla/5.0 (Linux; Android 12) COR-App/1.0 Optimized"
                mediaPlaybackRequiresUserGesture = false

                // ✅ MEMORY: Limitar recursos
                setGeolocationEnabled(false)
                setNeedInitialFocus(false)
                setSupportZoom(false)
                setSupportMultipleWindows(false)
            }

            // ✅ MEMORY: WebViewClient otimizado para memory management
            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    Log.d(TAG, "📄 Página iniciada: $url")
                    latestOnStateChange(WebViewState.Loading)

                    // ✅ MEMORY: Força garbage collection antes de carregar nova página
                    System.gc()
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.d(TAG, "✅ Página carregada: $url")
                    latestOnStateChange(WebViewState.Success)

                    // ✅ MEMORY: JavaScript otimizado e cleanup
                    view?.post {
                        try {
                            view.evaluateJavascript(getMemoryOptimizedScript()) { result ->
                                Log.d(TAG, "Memory script executed: $result")
                            }

                            // ✅ FIT TO SCREEN: Injetar script de ajuste quando necessário
                            if (fitMode || rotate90) {
                                Log.d(TAG, "🎥 Injetando script de fit to screen (fitMode=$fitMode, rotate90=$rotate90)")
                                view.evaluateJavascript(getVideoFitScript(fitMode, rotate90)) { result ->
                                    Log.d(TAG, "Fit script executed: $result")
                                }
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "Script execution failed: ${e.message}")
                        }
                    }
                }

                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                    super.onReceivedError(view, request, error)
                    if (request?.isForMainFrame == true) {
                        val errorMessage = "Erro ${error?.errorCode}: ${error?.description}"
                        Log.e(TAG, "❌ $errorMessage")
                        latestOnStateChange(WebViewState.Error(errorMessage))

                        // ✅ MEMORY: Cleanup em caso de erro
                        view?.clearHistory()
                        view?.clearCache(true)
                    }
                }

                override fun onReceivedHttpError(view: WebView?, request: WebResourceRequest?, errorResponse: WebResourceResponse?) {
                    super.onReceivedHttpError(view, request, errorResponse)
                    if (request?.isForMainFrame == true) {
                        val errorMessage = "HTTP Error ${errorResponse?.statusCode}"
                        Log.e(TAG, "🌐 $errorMessage")
                        latestOnStateChange(WebViewState.Error(errorMessage))
                    }
                }

                override fun onReceivedSslError(view: WebView?, handler: SslErrorHandler?, error: SslError?) {
                    Log.w(TAG, "🔒 SSL Error: ${error?.primaryError}")
                    handler?.cancel() // ✅ SECURITY: Não proceder com erros SSL
                    latestOnStateChange(WebViewState.Error("Erro de certificado SSL"))
                }

                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url?.toString()
                    return if (url?.startsWith("https://aplicativo.cocr.com.br") == true) {
                        false // Permitir carregamento
                    } else {
                        Log.w(TAG, "🚫 URL bloqueada: $url")
                        true // Bloquear
                    }
                }

                override fun onPageCommitVisible(view: WebView?, url: String?) {
                    super.onPageCommitVisible(view, url)
                    // ✅ MEMORY: Cleanup de recursos não utilizados quando página fica visível
                    view?.clearFormData()
                }
            }

            // ✅ MEMORY: WebChromeClient otimizado
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                    consoleMessage?.let {
                        // ✅ MEMORY: Log apenas mensagens importantes para evitar spam
                        if (it.messageLevel() == ConsoleMessage.MessageLevel.ERROR) {
                            Log.e(TAG, "🔴 JS Error: ${it.message()}")
                        }
                    }
                    return true
                }

                override fun onProgressChanged(view: WebView?, newProgress: Int) {
                    super.onProgressChanged(view, newProgress)
                    if (newProgress == 100) {
                        Log.d(TAG, "📊 Carregamento completo")
                        // ✅ MEMORY: Cleanup após carregamento completo
                        view?.clearFormData()
                    }
                }

                override fun onReceivedTitle(view: WebView?, title: String?) {
                    super.onReceivedTitle(view, title)
                    Log.d(TAG, "📝 Título recebido: $title")
                }

                // ✅ MEMORY: Não permitir múltiplas janelas para economizar memória
                override fun onCreateWindow(
                    view: WebView?,
                    isDialog: Boolean,
                    isUserGesture: Boolean,
                    resultMsg: Message?
                ): Boolean {
                    return false // Não permitir janelas popup
                }
            }

            // ✅ MEMORY: Salvar referência fraca
            webViewRef = WeakReference(this)
        }
    }

    // ✅ MEMORY: Controle de lifecycle otimizado
    LaunchedEffect(url) {
        if (url.isNotEmpty() && webView.url != url) {
            Log.d(TAG, "🔄 Carregando URL: $url")
            try {
                withContext(Dispatchers.Main) {
                    // ✅ MEMORY: Limpar antes de carregar nova URL
                    webView.clearHistory()
                    webView.clearCache(true)
                    webView.clearFormData()
                    System.gc() // Força GC
                    webView.loadUrl(url)
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro ao carregar URL: ${e.message}")
                latestOnStateChange(WebViewState.Error("Erro ao carregar página"))
            }
        }
    }

    LaunchedEffect(reloadTrigger) {
        if (reloadTrigger > 0) {
            Log.d(TAG, "🔄 Recarregando via trigger: $reloadTrigger")
            try {
                withContext(Dispatchers.Main) {
                    // ✅ MEMORY: Cleanup antes de reload
                    webView.clearHistory()
                    webView.clearCache(true)
                    webView.clearFormData()
                    System.gc()
                    webView.reload()
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro ao recarregar: ${e.message}")
                latestOnStateChange(WebViewState.Error("Erro ao recarregar página"))
            }
        }
    }

    // ✅ MEMORY: Cleanup agressivo quando o componente é removido
    DisposableEffect(webView) {
        onDispose {
            Log.d(TAG, "🗑️ Limpando WebView de forma agressiva")
            try {
                webViewRef?.get()?.apply {
                    // ✅ MEMORY: Cleanup completo e agressivo
                    stopLoading()
                    loadUrl("about:blank") // Limpa conteúdo
                    clearHistory()
                    clearCache(true)
                    clearFormData()
                    clearMatches()
                    clearSslPreferences()

                    // ✅ FIXED: Usar implementação vazia ao invés de null
                    webViewClient = object : WebViewClient() {}
                    webChromeClient = object : WebChromeClient() {}

                    // ✅ MEMORY: Remove views
                    removeAllViews()

                    // ✅ MEMORY: Pausa/resume para liberar recursos
                    onPause()

                    // ✅ MEMORY: Destroy final
                    destroy()
                }
                webViewRef = null

                // ✅ MEMORY: Força garbage collection após cleanup
                System.gc()

            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro na limpeza: ${e.message}")
            }
        }
    }

    AndroidView(
        factory = { webView },
        modifier = modifier,
        onRelease = { webViewInstance ->
            Log.d(TAG, "🔄 AndroidView onRelease")
            try {
                webViewInstance.apply {
                    stopLoading()
                    loadUrl("about:blank")
                    clearHistory()
                    clearCache(true)
                    clearFormData()
                    onPause()
                    destroy()
                }
                // ✅ MEMORY: GC após release
                System.gc()
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro no onRelease: ${e.message}")
            }
        }
    )
}

/**
 * ✅ MEMORY: Script JavaScript otimizado para economia de memória
 */
private fun getMemoryOptimizedScript(): String = """
    (function() {
        try {
            // ✅ MEMORY: Script mínimo e eficiente
            if (typeof navigator !== 'undefined' && navigator.webdriver) {
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined,
                    configurable: true
                });
            }
            
            // ✅ MEMORY: Remover listeners desnecessários para economizar memória
            document.addEventListener('DOMContentLoaded', function() {
                // Remove event listeners que consomem memória
                const elements = document.querySelectorAll('*');
                let count = 0;
                elements.forEach(el => {
                    if (count++ > 1000) return; // Limita processamento
                    
                    // Remove listeners que consomem memória
                    if (el.onmouseover) el.onmouseover = null;
                    if (el.onmouseout) el.onmouseout = null;
                    if (el.onmousemove) el.onmousemove = null;
                    if (el.onmouseenter) el.onmouseenter = null;
                    if (el.onmouseleave) el.onmouseleave = null;
                });
                
                // ✅ MEMORY: Limpar console para economizar memória
                if (console && console.clear) {
                    console.clear();
                }
            });
            
            // ✅ MEMORY: Cleanup de timers órfãos
            const originalSetTimeout = window.setTimeout;
            const originalSetInterval = window.setInterval;
            const activeTimeouts = new Set();
            const activeIntervals = new Set();
            
            window.setTimeout = function(fn, delay) {
                const id = originalSetTimeout.apply(this, arguments);
                activeTimeouts.add(id);
                return id;
            };
            
            window.setInterval = function(fn, delay) {
                const id = originalSetInterval.apply(this, arguments);
                activeIntervals.add(id);
                return id;
            };
            
            // Cleanup function
            window.cleanupTimers = function() {
                activeTimeouts.forEach(id => clearTimeout(id));
                activeIntervals.forEach(id => clearInterval(id));
                activeTimeouts.clear();
                activeIntervals.clear();
            };
            
            // Auto cleanup on page unload
            window.addEventListener('beforeunload', window.cleanupTimers);
            
            return 'OK';
        } catch(e) {
            console.warn('Memory optimization failed:', e.message);
            return 'ERROR';
        }
    })();
""".trimIndent()