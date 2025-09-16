package bugarin.t.comando.ui.components

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.net.http.SslError
import android.util.Log
import android.webkit.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

/**
 * Estados da WebView - Definido no início do arquivo
 */

/**
 * Composable que encapsula uma WebView nativa do Android
 * com tratamento de erros e estados.
 */
/**
 * Script para evitar detecção de WebView
 */
private fun getAntiDetectionScript(): String = """
    (function() {
        try {
            // Override webdriver
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            });
            
            // Add plugins
            Object.defineProperty(navigator, 'plugins', {
                get: () => [1, 2, 3, 4, 5]
            });
            
            // Add chrome
            window.chrome = {
                runtime: {},
                loadTimes: function() {},
                csi: function() {},
                app: {}
            };
            
            // Fix permissions
            const originalQuery = window.navigator.permissions.query;
            window.navigator.permissions.query = (parameters) => (
                parameters.name === 'notifications' ?
                    Promise.resolve({ state: 'granted' }) :
                    originalQuery(parameters)
            );
            
            // Remove automation indicators
            delete navigator.__proto__.webdriver;
            
            console.log('Anti-detection applied');
        } catch(e) {
            console.error('Anti-detection error:', e);
        }
    })();
""".trimIndent()

/**
 * Script para corrigir problemas com iframes
 */
private fun getIframeFixScript(): String = """
    (function() {
        try {
            const iframes = document.querySelectorAll('iframe');
            console.log('Found ' + iframes.length + ' iframes');
            
            iframes.forEach(function(iframe, index) {
                // Forçar dimensões
                iframe.style.width = '100%';
                iframe.style.height = '100vh';
                iframe.style.border = 'none';
                iframe.style.display = 'block';
                
                // Remover sandbox restrictions se houver
                iframe.removeAttribute('sandbox');
                
                // Adicionar allow attributes
                iframe.setAttribute('allow', 'geolocation; microphone; camera; payment; autoplay; fullscreen');
                
                console.log('Fixed iframe ' + index);
            });
            
            // Observar mudanças no DOM para novos iframes
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'IFRAME') {
                            node.style.width = '100%';
                            node.style.height = '100vh';
                            node.style.border = 'none';
                            node.style.display = 'block';
                            console.log('Fixed new iframe');
                        }
                    });
                });
            });
            
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
            
        } catch(e) {
            console.error('Iframe fix error:', e);
        }
    })();
""".trimIndent()