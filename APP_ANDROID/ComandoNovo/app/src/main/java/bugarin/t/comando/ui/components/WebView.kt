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

/**
 * Script para ajustar vídeo à tela (fit to screen) com object-fit contain
 */
fun getVideoFitScript(fitMode: Boolean = true, rotate90: Boolean = false): String = """
    (function() {
        try {
            console.log('🎥 Aplicando fit to screen - fitMode: $fitMode, rotate90: $rotate90');

            // Função para garantir viewport correto
            function ensureViewport() {
                let viewport = document.querySelector('meta[name="viewport"]');
                if (!viewport) {
                    viewport = document.createElement('meta');
                    viewport.name = 'viewport';
                    document.head.appendChild(viewport);
                }
                viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
                console.log('✅ Viewport configurado');
            }

            // Função para injetar CSS
            function injectCSS() {
                const styleId = 'video-fit-style';
                let style = document.getElementById(styleId);
                if (!style) {
                    style = document.createElement('style');
                    style.id = styleId;
                    document.head.appendChild(style);
                }

                const rotation = ${if (rotate90) "90" else "0"};
                const objectFit = ${if (fitMode) "'contain'" else "'cover'"};

                style.textContent = `
                    html, body {
                        margin: 0 !important;
                        padding: 0 !important;
                        width: 100vw !important;
                        height: 100vh !important;
                        overflow: hidden !important;
                        background: #000 !important;
                        position: relative !important;
                    }

                    body > * {
                        margin: 0 !important;
                        padding: 0 !important;
                    }

                    #player, .player, .video-container, [id*="player"], [class*="player"] {
                        width: 100vw !important;
                        height: 100vh !important;
                        margin: 0 !important;
                        padding: 0 !important;
                        position: fixed !important;
                        top: 0 !important;
                        left: 0 !important;
                    }

                    video, img, canvas {
                        object-fit: ${'$'}{objectFit} !important;
                        width: 100vw !important;
                        height: 100vh !important;
                        max-width: none !important;
                        max-height: none !important;
                        position: fixed !important;
                        top: 50% !important;
                        left: 50% !important;
                        transform: translate(-50%, -50%) rotate(${'$'}{rotation}deg) !important;
                        transform-origin: center center !important;
                        margin: 0 !important;
                        padding: 0 !important;
                        border: none !important;
                        background: #000 !important;
                    }

                    @media (orientation: portrait) {
                        video, img, canvas {
                            object-fit: ${'$'}{objectFit} !important;
                            width: 100vw !important;
                            height: 100vh !important;
                        }
                    }

                    @media (orientation: landscape) {
                        video, img, canvas {
                            object-fit: ${'$'}{objectFit} !important;
                            width: 100vw !important;
                            height: 100vh !important;
                        }
                    }
                `;

                console.log('✅ CSS injetado');
            }

            // Função para aplicar layout aos elementos de vídeo
            function applyLayout() {
                const videos = document.querySelectorAll('video');
                const images = document.querySelectorAll('img');
                const canvases = document.querySelectorAll('canvas');

                console.log('🎬 Encontrados: ' + videos.length + ' vídeos, ' + images.length + ' imagens, ' + canvases.length + ' canvas');

                [...videos, ...images, ...canvases].forEach(function(el) {
                    // Adicionar playsinline para iOS
                    if (el.tagName === 'VIDEO') {
                        el.setAttribute('playsinline', '');
                        el.setAttribute('webkit-playsinline', '');
                        el.muted = false; // Permitir som

                        // Garantir que o vídeo está visível
                        el.style.visibility = 'visible';
                        el.style.display = 'block';
                    }

                    console.log('✅ Elemento configurado: ' + el.tagName);
                });

                // Aplicar aos containers também
                const containers = document.querySelectorAll('#player, .player, .video-container, [id*="player"], [class*="player"]');
                containers.forEach(function(container) {
                    container.style.width = '100vw';
                    container.style.height = '100vh';
                    container.style.margin = '0';
                    container.style.padding = '0';
                    console.log('✅ Container configurado');
                });
            }

            // Aplicar imediatamente
            ensureViewport();
            injectCSS();
            applyLayout();

            // Reaplicar em eventos importantes
            window.addEventListener('resize', function() {
                console.log('🔄 Resize detectado, reaplicando layout');
                injectCSS();
                applyLayout();
            });

            window.addEventListener('orientationchange', function() {
                console.log('🔄 Orientação mudou, reaplicando layout');
                setTimeout(function() {
                    injectCSS();
                    applyLayout();
                }, 100);
            });

            // Observar vídeos e aplicar quando carregarem
            const videos = document.querySelectorAll('video');
            videos.forEach(function(video) {
                video.addEventListener('loadedmetadata', function() {
                    console.log('🎬 Vídeo metadata carregada');
                    applyLayout();
                });

                video.addEventListener('play', function() {
                    console.log('▶️ Vídeo iniciou');
                    applyLayout();
                });

                video.addEventListener('timeupdate', function() {
                    if (video.currentTime < 1 && video.currentTime > 0) {
                        applyLayout();
                    }
                });
            });

            // Observar mudanças no DOM
            const observer = new MutationObserver(function(mutations) {
                let hasNewMedia = false;
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'VIDEO' || node.tagName === 'IMG' || node.tagName === 'CANVAS') {
                            hasNewMedia = true;
                        }
                    });
                });

                if (hasNewMedia) {
                    console.log('🆕 Nova mídia detectada, reaplicando layout');
                    setTimeout(applyLayout, 100);
                }
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true
            });

            // Timeouts múltiplos para garantir aplicação
            setTimeout(applyLayout, 200);
            setTimeout(applyLayout, 600);
            setTimeout(applyLayout, 1200);
            setTimeout(applyLayout, 2000);

            console.log('✅ Script de fit to screen aplicado com sucesso');
            return 'OK';

        } catch(e) {
            console.error('❌ Erro no script de fit:', e.message);
            return 'ERROR: ' + e.message;
        }
    })();
""".trimIndent()