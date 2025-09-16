import SwiftUI
import WebKit

//====================================================================//
// MARK: - View de Tela Cheia do Radar (Versão Final)
//====================================================================//
struct FullScreenRadarView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading: Bool = true
    @State private var loadError: Error? = nil
    
    private let radarURL = URL(string: "https://aplicativo.cocr.com.br/radar_emb_app")

    var body: some View {
        // MUDANÇA: A view agora é uma VStack para separar o header do conteúdo
        VStack(spacing: 0) {
            // NOVO: Cabeçalho padronizado, igual ao das outras telas
            HeaderRadarFullScreenView(onDismiss: { dismiss() })
            
            ZStack {
                // Conteúdo do WebView
                if let url = radarURL {
                    WebView(
                        url: url,
                        isScrollEnabled: true,
                        isLoading: $isLoading,
                        error: $loadError
                    )
                } else {
                    EmptyStateView(icon: "link.circle.fill", message: "URL do radar inválida.")
                }
                
                // MUDANÇA: Camada de Loading agora usa a animação personalizada
                if isLoading {
                    // Usamos um fundo para o loading não ficar "flutuando" sobre o conteúdo da web
                    Color.white.opacity(0.9)
                    
                    ZStack {
                        BrandedLoadingView() // Sua animação de logo pulsante
                        RadarSweepView()     // A animação de varredura
                    }
                }
                
                // Camada de Erro (usando a EmptyStateView padronizada)
                if loadError != nil {
                    EmptyStateView(
                        icon: "wifi.exclamationmark",
                        message: "Falha ao carregar o radar",
                        actionTitle: "Tentar Novamente"
                    ) {
                        self.loadError = nil
                        self.isLoading = true
                    }
                    .background(.regularMaterial)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}


//====================================================================//
// MARK: - Componentes da Tela Cheia do Radar
//====================================================================//

private struct HeaderRadarFullScreenView: View {
    var onDismiss: () -> Void

    var body: some View {
        HStack {
            Text("Radar Meteorológico")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark") // Usamos um 'x' simples aqui
                    .font(.body.weight(.bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.thinMaterial) // Efeito de vidro fosco
    }
}

