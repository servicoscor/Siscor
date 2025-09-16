import SwiftUI
import WebKit

//====================================================================//
// MARK: - View Principal: RadarCardView
//====================================================================//
struct RadarCardView: View {
    let onExpand: () -> Void
    
    @State private var isLoading: Bool = true
    @State private var loadError: Error? = nil
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // É mais seguro não forçar o unwrap aqui
    private let radarURL = URL(string: "https://aplicativo.cocr.com.br/radar_emb_app")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho do Card
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 20))
                Text(localizationManager.string(for: "radar"))
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel(localizationManager.string(for: "expand_radar"))
            }
            .foregroundColor(.white)
            .padding()

            // ZStack para sobrepor o indicador de loading sobre o WebView
            ZStack {
                // Conteúdo do WebView
                if let url = radarURL {
                    WebView(
                        url: url,
                        isScrollEnabled: false,
                        isLoading: $isLoading,
                        error: $loadError
                    )
                } else {
                    // Fallback se a URL for inválida
                    EmptyStateView(
                        icon: "link.circle.fill",
                        message: localizationManager.string(for: "invalid_radar_url")
                    )
                }
                
                // Camada de Loading com animações
                if isLoading {
                    ZStack {
                        BrandedLoadingView(
                            message: localizationManager.string(for: "loading_radar")
                        )
                        RadarSweepView() // A animação de varredura
                    }
                }
                
                // Camada de Erro
                if loadError != nil {
                    EmptyStateView(
                        icon: "wifi.exclamationmark",
                        message: localizationManager.string(for: "radar_load_error"),
                        actionTitle: localizationManager.string(for: "try_again")
                    ) {
                        // Ação do botão para tentar novamente
                        self.loadError = nil
                        self.isLoading = true // Reinicia o ciclo de carregamento
                    }
                    .background(.black.opacity(0.6))
                    .cornerRadius(10)
                }
            }
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding([.horizontal, .bottom], 8)
        }
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
}

//====================================================================//
// MARK: - Componentes de UI e Animação
//====================================================================//

// Animação de varredura do radar
struct RadarSweepView: View {
    @State private var angle: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [.green.opacity(0.5), .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: 140, height: 140)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

// EmptyStateView localizada
struct EmptyStateView: View {
    let icon: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.7))
            Text(message)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .padding(.top, 8)
                    .tint(.yellow)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//====================================================================//
// MARK: - Estilos e Preview
//====================================================================//
private let cardGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.1, green: 0.5, blue: 0.9),
        Color(red: 0.3, green: 0.6, blue: 0.9)
    ]),
    startPoint: .top,
    endPoint: .bottom
)

private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.2), lineWidth: 1)
}

struct RadarCardView_Previews: PreviewProvider {
    static var previews: some View {
        RadarCardView(onExpand: {})
            .padding()
            .background(Color.gray)
    }
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

