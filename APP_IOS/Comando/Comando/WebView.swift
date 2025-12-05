//  WebView.swift

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    var isScrollEnabled: Bool = true
    var coverMode: Bool = false   // modo "preencher cortando"
    var fitMode: Bool = false     // modo "enquadrar sem cortar"
    var rotate90: Bool = false    // rotacionar mídia 90°

    @Binding var isLoading: Bool
    @Binding var error: Error?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        if coverMode || fitMode || rotate90 {
            // CSS base
            let baseCSS = """
            html, body {
                margin: 0 !important;
                padding: 0 !important;
                background: #000 !important;
                width: 100vw !important;
                height: 100vh !important;
                overflow: hidden !important;
            }
            #player, .player, .video-container, .container, .wrapper {
                width: 100vw !important;
                height: 100vh !important;
                margin: 0 !important;
                padding: 0 !important;
                background: #000 !important;
            }
            """

            let objectFitRule: String = coverMode ? "object-fit: cover !important;" : "object-fit: contain !important;"
            let rotationTransform: String = rotate90 ? "rotate(90deg)" : "none"

            // CSS para mídia
            let mediaCSS: String = """
            video, img, canvas {
                position: fixed !important;
                top: 50% !important;
                left: 50% !important;
                transform: translate(-50%, -50%) \(rotationTransform) !important;
                background: #000 !important;
                max-width: none !important;
                max-height: none !important;
                \(objectFitRule)
            }
            /* Dimensões considerando rotação 90°: usamos 100vh x 100vw para ocupar a viewport rotacionada */
            @media (orientation: portrait) {
                video, img, canvas {
                    width: \(rotate90 ? "100vh" : "100vw") !important;
                    height: \(rotate90 ? "100vw" : "100vh") !important;
                }
            }
            @media (orientation: landscape) {
                video, img, canvas {
                    width: \(rotate90 ? "100vh" : "100vw") !important;
                    height: \(rotate90 ? "100vw" : "100vh") !important;
                }
            }
            """

            let css = baseCSS + mediaCSS

            // JS comum: meta viewport + aplicar CSS + reaplicar após eventos
            let commonJS = """
            (function() {
                function ensureViewport() {
                    try {
                        var metas = document.getElementsByTagName('meta');
                        for (var i = 0; i < metas.length; i++) {
                            if (metas[i].name === 'viewport') return;
                        }
                        var meta = document.createElement('meta');
                        meta.name = 'viewport';
                        meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
                        document.head.appendChild(meta);
                    } catch(e) {}
                }

                function injectCSS() {
                    try {
                        var style = document.createElement('style');
                        style.type = 'text/css';
                        style.appendChild(document.createTextNode(`\(css)`));
                        document.head.appendChild(style);
                    } catch(e) {}
                }

                function applyLayout() {
                    try {
                        document.documentElement.style.width = '100vw';
                        document.documentElement.style.height = '100vh';
                        document.body.style.width = '100vw';
                        document.body.style.height = '100vh';

                        var vids = document.getElementsByTagName('video');
                        for (var i = 0; i < vids.length; i++) {
                            var v = vids[i];
                            v.setAttribute('playsinline', 'true');
                            v.setAttribute('webkit-playsinline', 'true');
                            v.style.webkitTransform = v.style.transform;
                        }

                        var imgs = document.getElementsByTagName('img');
                        for (var j = 0; j < imgs.length; j++) {
                            var im = imgs[j];
                            im.style.webkitTransform = im.style.transform;
                        }

                        var canv = document.getElementsByTagName('canvas');
                        for (var k = 0; k < canv.length; k++) {
                            var c = canv[k];
                            c.style.webkitTransform = c.style.transform;
                        }
                    } catch(e) {}
                }

                ensureViewport();
                injectCSS();
                applyLayout();

                window.addEventListener('resize', applyLayout);
                document.addEventListener('loadedmetadata', applyLayout, true);
                document.addEventListener('play', applyLayout, true);
                document.addEventListener('timeupdate', applyLayout, true);

                // Reaplicações tardias para páginas que mexem no DOM
                setTimeout(applyLayout, 200);
                setTimeout(applyLayout, 600);
                setTimeout(applyLayout, 1200);
                setTimeout(applyLayout, 2000);
            })();
            """

            // Injetar também em subframes (iframes)
            let startScript = WKUserScript(source: commonJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            let endScript = WKUserScript(source: commonJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            config.userContentController.addUserScript(startScript)
            config.userContentController.addUserScript(endScript)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = isScrollEnabled

        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.scrollView.isScrollEnabled != isScrollEnabled {
            uiView.scrollView.isScrollEnabled = isScrollEnabled
        }
        context.coordinator.coverMode = coverMode

        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, coverMode: coverMode)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var coverMode: Bool

        init(_ parent: WebView, coverMode: Bool) {
            self.parent = parent
            self.coverMode = coverMode
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.error = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.error = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.error = error
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.error = error
        }
    }
}
