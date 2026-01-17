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
 * Representa os possi­veis estados do ControlledWebView.
 */
sealed class WebViewState {
    data object Loading : WebViewState()
    data object Success : WebViewState()
    data class Error(val message: String? = null) : WebViewState()
}

/**
 *  MEMORY OPTIMIZED: WebView com melhor gerenciamento de memoria e cleanup
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
    allowedHosts: Set<String> = setOf("aplicativo.cocr.com.br"),
    allowMixedContent: Boolean = false,
    customUserAgent: String? = null,
    useDefaultUserAgent: Boolean = false,
    allowThirdPartyCookies: Boolean = false,
    enableMemoryOptimizations: Boolean = true
) {
    val TAG = "ControlledWebView-$sessionId"
    val context = LocalContext.current
    val latestOnStateChange by rememberUpdatedState(onStateChange)

    //  MEMORY: WeakReference para evitar memory leaks
    var webViewRef by remember { mutableStateOf<WeakReference<WebView>?>(null) }

    //  MEMORY: WebView otimizado com cleanup adequado e configurações de memoria
    val webView = remember {
        WebView(context).apply {
            settings.apply {
                //  PERFORMANCE: Configurações otimizadas
                javaScriptEnabled = true
                domStorageEnabled = true
                loadWithOverviewMode = true
                useWideViewPort = true
                builtInZoomControls = false
                displayZoomControls = false

                //  MEMORY: Configurações de cache e memoria otimizadas
                cacheMode = if (enableMemoryOptimizations) {
                    WebSettings.LOAD_NO_CACHE
                } else {
                    WebSettings.LOAD_DEFAULT
                }
                // FIXED: Removido setAppCacheEnabled e setAppCacheMaxSize - deprecated
                databaseEnabled = !enableMemoryOptimizations

                //  MEMORY: Configurações de memoria especi­ficas
                setRenderPriority(
                    if (enableMemoryOptimizations) {
                        WebSettings.RenderPriority.HIGH
                    } else {
                        WebSettings.RenderPriority.NORMAL
                    }
                )
                if (enableMemoryOptimizations) {
                    setLayoutAlgorithm(WebSettings.LayoutAlgorithm.TEXT_AUTOSIZING)
                }

                //  SECURITY: Configurações de segurança
                mixedContentMode = if (allowMixedContent) {
                    WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                } else {
                    WebSettings.MIXED_CONTENT_NEVER_ALLOW
                }
                allowFileAccess = false
                allowContentAccess = false
                allowFileAccessFromFileURLs = false
                allowUniversalAccessFromFileURLs = false

                //  MEMORY: User agent otimizado
                userAgentString = when {
                    customUserAgent != null -> customUserAgent
                    useDefaultUserAgent -> WebSettings.getDefaultUserAgent(context)
                    else -> "Mozilla/5.0 (Linux; Android 12) COR-App/1.0 Optimized"
                }
                mediaPlaybackRequiresUserGesture = false

                //  MEMORY: Limitar recursos
                setGeolocationEnabled(false)
                setNeedInitialFocus(false)
                setSupportZoom(false)
                setSupportMultipleWindows(false)
            }

            //  MEMORY: WebViewClient otimizado para memory management
            CookieManager.getInstance().setAcceptCookie(true)
            if (allowThirdPartyCookies) {
                CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
            }

            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    Log.d(TAG, " Pagina iniciada: $url")
                    latestOnStateChange(WebViewState.Loading)

                    // âœ… MEMORY: Força garbage collection antes de carregar nova pÃ¡gina
                    if (enableMemoryOptimizations) {
                        System.gc()
                    }
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.d(TAG, "pagina carregada: $url")
                    latestOnStateChange(WebViewState.Success)

                    // âœ… MEMORY: JavaScript otimizado e cleanup
                    view?.post {
                        try {
                            if (enableMemoryOptimizations) {
                                view.evaluateJavascript(getMemoryOptimizedScript()) { result ->
                                    Log.d(TAG, "Memory script executed: $result")
                                }
                            }

                            // âœ… FIT TO SCREEN: Injetar script de ajuste quando necessÃ¡rio
                            if (fitMode || rotate90) {
                                Log.d(TAG, " Injetando script de fit to screen (fitMode=$fitMode, rotate90=$rotate90)")
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
                        Log.e(TAG, "$errorMessage")
                        latestOnStateChange(WebViewState.Error(errorMessage))

                        // ?o. MEMORY: Cleanup em caso de erro
                        if (enableMemoryOptimizations) {
                            view?.clearHistory()
                            view?.clearCache(true)
                        }
                    }
                }

                override fun onReceivedHttpError(view: WebView?, request: WebResourceRequest?, errorResponse: WebResourceResponse?) {
                    super.onReceivedHttpError(view, request, errorResponse)
                    if (request?.isForMainFrame == true) {
                        val errorMessage = "HTTP Error ${errorResponse?.statusCode}"
                        Log.e(TAG, " $errorMessage")
                        latestOnStateChange(WebViewState.Error(errorMessage))
                    }
                }

                override fun onReceivedSslError(view: WebView?, handler: SslErrorHandler?, error: SslError?) {
                    Log.w(TAG, " Error: ${error?.primaryError}")
                    handler?.cancel() // âœ… SECURITY: Não proceder com erros SSL
                    latestOnStateChange(WebViewState.Error("Erro de certificado SSL"))
                }

                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url?.toString()
                    val host = request?.url?.host?.lowercase()

                    if (url == null || url.startsWith("about:")) {
                        return false
                    }

                    if (allowedHosts.isEmpty()) {
                        return false
                    }

                    val isAllowedHost = host != null && allowedHosts.any { allowed ->
                        host == allowed.lowercase() || host.endsWith(".${allowed.lowercase()}")
                    }

                    return if (isAllowedHost) {
                        false
                    } else {
                        Log.w(TAG, " URL bloqueada: $url")
                        true
                    }
                }

                override fun onPageCommitVisible(view: WebView?, url: String?) {
                    super.onPageCommitVisible(view, url)
                    //  MEMORY: Cleanup de recursos nÃ£o utilizados quando pagina fica visa­vel
                    view?.clearFormData()
                }
            }

            // MEMORY: WebChromeClient otimizado
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                    consoleMessage?.let {
                        //  MEMORY: Log apenas mensagens importantes para evitar spam
                        if (it.messageLevel() == ConsoleMessage.MessageLevel.ERROR) {
                            Log.e(TAG, " JS Error: ${it.message()}")
                        }
                    }
                    return true
                }

                override fun onProgressChanged(view: WebView?, newProgress: Int) {
                    super.onProgressChanged(view, newProgress)
                    if (newProgress == 100) {
                        Log.d(TAG, "Carregamento completo")
                        //  MEMORY: Cleanup apÃ³s carregamento completo
                        view?.clearFormData()
                    }
                }

                override fun onReceivedTitle(view: WebView?, title: String?) {
                    super.onReceivedTitle(view, title)
                    Log.d(TAG, " Titulo recebido: $title")
                }

                //  MEMORY: Não permitir mÃºltiplas janelas para economizar memoria
                override fun onCreateWindow(
                    view: WebView?,
                    isDialog: Boolean,
                    isUserGesture: Boolean,
                    resultMsg: Message?
                ): Boolean {
                    return false // Não permitir janelas popup
                }
            }

            // MEMORY: Salvar referÃªncia fraca
            webViewRef = WeakReference(this)
        }
    }

    // MEMORY: Controle de lifecycle otimizado
    LaunchedEffect(url) {
        if (url.isNotEmpty() && webView.url != url) {
            Log.d(TAG, " Carregando URL: $url")
            try {
                withContext(Dispatchers.Main) {
                    //  MEMORY: Limpar antes de carregar nova URL
                    if (enableMemoryOptimizations) {
                        webView.clearHistory()
                        webView.clearCache(true)
                        webView.clearFormData()
                        System.gc() // Fora GC
                    }
                    webView.loadUrl(url)
                }
            } catch (e: Exception) {
                Log.e(TAG, " Erro ao carregar URL: ${e.message}")
                latestOnStateChange(WebViewState.Error("Erro ao carregar pagina"))
            }
        }
    }

    LaunchedEffect(reloadTrigger) {
        if (reloadTrigger > 0) {
            Log.d(TAG, " Recarregando via trigger: $reloadTrigger")
            try {
                withContext(Dispatchers.Main) {
                    // MEMORY: Cleanup antes de reload
                    if (enableMemoryOptimizations) {
                        webView.clearHistory()
                        webView.clearCache(true)
                        webView.clearFormData()
                        System.gc()
                    }
                    webView.reload()
                }
            } catch (e: Exception) {
                Log.e(TAG, " Erro ao recarregar: ${e.message}")
                latestOnStateChange(WebViewState.Error("Erro ao recarregar pagina"))
            }
        }
    }

    //  MEMORY: Cleanup agressivo quando o componente removido
    DisposableEffect(webView) {
        onDispose {
            Log.d(TAG, " Limpando WebView de forma agressiva")
            try {
                webViewRef?.get()?.apply {
                    // MEMORY: Cleanup completo e agressivo
                    stopLoading()
                    loadUrl("about:blank") // Limpa conteudo
                    clearHistory()
                    clearCache(true)
                    clearFormData()
                    clearMatches()
                    clearSslPreferences()

                    //  FIXED: Usar implementação vazia ao inves de null
                    webViewClient = object : WebViewClient() {}
                    webChromeClient = object : WebChromeClient() {}

                    //  MEMORY: Remove views
                    removeAllViews()

                    //  MEMORY: Pausa/resume para liberar recursos
                    onPause()

                    //  MEMORY: Destroy final
                    destroy()
                }
                webViewRef = null

                //  MEMORY: ForÃ§a garbage collection aps cleanup
                System.gc()

            } catch (e: Exception) {
                Log.e(TAG, " Erro na limpeza: ${e.message}")
            }
        }
    }

    AndroidView(
        factory = { webView },
        modifier = modifier,
        onRelease = { webViewInstance ->
            Log.d(TAG, " AndroidView onRelease")
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
                //  MEMORY: GC aps release
                System.gc()
            } catch (e: Exception) {
                Log.e(TAG, " Erro no onRelease: ${e.message}")
            }
        }
    )
}

/**
 *  MEMORY: Script JavaScript otimizado para economia de memoria
 */
private fun getMemoryOptimizedScript(): String = """
    (function() {
        try {
            //  MEMORY: Script minimo e eficiente
            if (typeof navigator !== 'undefined' && navigator.webdriver) {
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined,
                    configurable: true
                });
            }
            
            //  MEMORY: Remover listeners desnecessÃ¡rios para economizar memoria
            document.addEventListener('DOMContentLoaded', function() {
                // Remove event listeners que consomem memoria
                const elements = document.querySelectorAll('*');
                let count = 0;
                elements.forEach(el => {
                    if (count++ > 1000) return; // Limita processamento
                    
                    // Remove listeners que consomem memoria
                    if (el.onmouseover) el.onmouseover = null;
                    if (el.onmouseout) el.onmouseout = null;
                    if (el.onmousemove) el.onmousemove = null;
                    if (el.onmouseenter) el.onmouseenter = null;
                    if (el.onmouseleave) el.onmouseleave = null;
                });
                
                // âœ… MEMORY: Limpar console para economizar memoria
                if (console && console.clear) {
                    console.clear();
                }
            });
            
            //  MEMORY: Cleanup de timers 
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


