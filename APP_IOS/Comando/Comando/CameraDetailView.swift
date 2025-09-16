import SwiftUI
import WebKit

// MARK: - Tela de Detalhes da Câmera (Refatorada)
struct CameraDetailView: View {
    // MARK: Propriedades e Dependências
    let camera: Camera
    
    // @Binding var isFavorite: Bool // 1. Removido para simplificar
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var localizationManager: LocalizationManager // ✅ Recebido do ambiente
    @StateObject private var orientationManager = OrientationManager.shared
    
    // MARK: Estado da View
    @State private var isLoading: Bool = true
    @State private var error: Error? = nil
    
    // MARK: Propriedades Computadas
    private var streamURL: URL? {
        guard let apiId = camera.apiId else { return nil }
        return URL(string: "https://aplicativo.cocr.com.br/camera/\(apiId)")
    }
    
    /// 2. Propriedade computada para ler o estado de favorito diretamente do manager.
    private var isCurrentlyFavorite: Bool {
        favoritesManager.isFavorite(camera.id)
    }
    
    // MARK: Corpo da View
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra superior de controle
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(localizationManager.string(for: "close"))
                    
                    Spacer()
                    
                    Text(camera.nome ?? localizationManager.string(for: "camera"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 3. Botão de favorito simplificado, usando a fonte única da verdade.
                    Button(action: {
                        favoritesManager.toggleFavorite(camera.id)
                    }) {
                        Image(systemName: isCurrentlyFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(isCurrentlyFavorite ? .yellow : .white)
                            .padding(10)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isCurrentlyFavorite ?
                        localizationManager.string(for: "remove_from_favorites") :
                        localizationManager.string(for: "add_to_favorites"))
                }
                .padding()
                
                // Conteúdo principal com WebView e overlays
                ZStack {
                    if let url = streamURL {
                        WebView(
                            url: url,
                            isScrollEnabled: false,
                            isLoading: $isLoading,
                            error: $error
                        )
                        .background(Color.black)
                    } else {
                        Text(localizationManager.string(for: "invalid_camera_id"))
                            .foregroundColor(.gray)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    // Mostrar erro se houver
                    if let error = error {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                            
                            Text(localizationManager.string(for: "error_loading"))
                                .foregroundColor(.white)
                            
                            Text(localizedErrorDescription(for: error))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .statusBar(hidden: true)
        // 4. Lógica do onAppear simplificada.
        .onAppear {
            orientationManager.lockToLandscape()
        }
        .onDisappear {
            orientationManager.lockToPortrait()
        }
    }
    
    // MARK: Funções Auxiliares
    
    /// Função auxiliar para traduzir descrições de erro comuns.
    private func localizedErrorDescription(for error: Error) -> String {
        let nsError = error as NSError
        
        // Verifica erros de rede comuns
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return localizationManager.string(for: "error_no_internet")
            case NSURLErrorTimedOut:
                return localizationManager.string(for: "error_timeout")
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return localizationManager.string(for: "error_server_unavailable")
            default:
                return localizationManager.string(for: "error_network_generic")
            }
        }
        
        // Fallback para a descrição localizada do erro
        return error.localizedDescription
    }
}
