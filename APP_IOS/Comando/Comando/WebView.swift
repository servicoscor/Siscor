//  WebView.swift

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    var isScrollEnabled: Bool = true // Mantido do seu código, com valor padrão

    // Bindings para comunicar o estado de carregamento e erro
    @Binding var isLoading: Bool
    @Binding var error: Error?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // --- Configurações do seu WebView original ---
        webView.allowsBackForwardNavigationGestures = true // Mantido
        webView.isOpaque = false // Mantido
        webView.backgroundColor = .clear // Mantido
        // --- Fim das configurações originais ---
        
        webView.scrollView.isScrollEnabled = isScrollEnabled
        
        // O Coordinator atuará como o "delegado" para ouvir os eventos
        webView.navigationDelegate = context.coordinator
        
        // Carrega a URL apenas uma vez, na criação da view
        webView.load(URLRequest(url: url))
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Atualiza a propriedade de scroll se ela mudar
        if uiView.scrollView.isScrollEnabled != isScrollEnabled {
            uiView.scrollView.isScrollEnabled = isScrollEnabled
        }
        
        // Otimização: Só recarrega a página se a URL for diferente da atual
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    // Cria o Coordinator que conecta o mundo do UIKit (WKWebView) ao SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // Inicia o loading
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.error = nil
        }

        // Finaliza o loading com sucesso
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.error = nil
        }

        // Finaliza o loading com erro
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
